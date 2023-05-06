import { Component, OnInit, Input, OnDestroy } from "@angular/core";
import {
  ModalController,
  AlertController,
  LoadingController,
} from "@ionic/angular";
import { Subscription } from "rxjs";
import { Store } from "@ngrx/store";
import * as fromApp from "../../store/app.reducer";
import * as selectors from "../../store/app.selectors";
import { auditTime, distinctUntilChanged, map } from "rxjs/operators";
import * as _ from "lodash";
import { DataStorageService } from "../../shared/data-storage.service";
import { TranslateService } from "@ngx-translate/core";
import { UnicModal } from "../unicModal/unic-modal.component";

@Component({
  selector: "app-edit-modal",
  templateUrl: "./edit.modal.component.html",
})
export class EditStoreModal implements OnInit, OnDestroy {
  modal: HTMLIonModalElement;
  @Input() editstore: any;
  @Input() thisModalInstance: any;
  public editedStore: any;
  public onDeleteDisable: boolean;
  public onValidDisable: boolean;
  public onInvalidDisable: boolean;
  public onCustomerDisable: boolean;

  public subscription: Subscription;
  public storeName: string;
  public formattedAddress: string;
  public store_category: any;
  public fist_time: boolean = true;
  constructor(
    public modalController: ModalController,
    private dataStorageService: DataStorageService,
    private alertController: AlertController,
    private store: Store<fromApp.AppState>,
    private translate: TranslateService,
    private loadingController: LoadingController
  ) {}

  ngOnInit() {
    this.subscription = this.store
      .select(selectors.getItemByStoreName(this.editstore.timestamp))
      .pipe(distinctUntilChanged())
      .pipe(auditTime(100))
      .subscribe((item) => {
        if (item && !_.isEqual(item, this.editedStore) && this.fist_time) {
          this.editedStore = _.cloneDeep(item);
          this.initializeActions();
          this.fist_time = false;

          console.log("selector store", this.editedStore);
        }

        if (
          item &&
          this.editedStore &&
          !_.isEqual(item.invalid, this.editedStore.invalid)
        ) {
          this.editedStore.invalid = _.cloneDeep(item.invalid);
          this.initializeActions();
          this.fist_time = false;
        }

        if (
          item &&
          this.editedStore &&
          !_.isEqual(item.invalid, this.editedStore.invalid)
        ) {
          this.editedStore.isCustomer = _.cloneDeep(item.isCustomer);
          this.initializeActions();
          this.fist_time = false;
        }

        if (
          item &&
          this.editedStore &&
          !_.isEqual(item.invalid, this.editedStore.invalid)
        ) {
          this.editedStore.checked = _.cloneDeep(item.checked);
          this.initializeActions();
          this.fist_time = false;
        }
      });
  }

  initializeActions() {
    if (!this.editedStore.store_category) {
      this.store_category = [];
    } else this.store_category = this.editedStore.store_category;
    if (
      !this.editedStore.invalid &&
      this.editedStore.checked &&
      !this.editedStore.isCustomer
    ) {
      this.onValidDisable = true;
      this.onDeleteDisable = true;
      this.onInvalidDisable = false;
      this.onCustomerDisable = false;
    }
    if (this.editedStore.invalid) {
      this.onInvalidDisable = true;
      this.onValidDisable = false;
      this.onDeleteDisable = false;
      this.onCustomerDisable = false;
    }
    if (this.editedStore.isCustomer) {
      this.onCustomerDisable = true;
      this.onInvalidDisable = false;
      this.onValidDisable = false;
      this.onDeleteDisable = false;
    }
  }

  async callUnicModal(action) {
    return await this.showUnicModal(action, this.editedStore);
  }

  private async showUnicModal(action, store) {
    const modal = await this.modalController.create({
      component: UnicModal,
      backdropDismiss: false,
      cssClass: "unic-modal-Css",
      componentProps: { editstore: _.cloneDeep(store), action: action },
    });
    await modal.present();
    modal.onDidDismiss().then((data) => {
      console.log("dissmiss data", data);
      if (data && data.data && data.data === "closeModal") {
        if (this.modal) {
          // this.modal.dismiss("closeModal");
          // this.modal = null;
        }
      }
      if (data && data.data && data.data === "delete") {
        this.thisModalInstance.dismiss();
        this.modal.dismiss("closeModal");
        this.modal = null;
      }
    });
  }

  async saveStore() {
    if (!this.editedStore) {
    } else {
      if (!this.editedStore.formatted_address || !this.editedStore.store_name) {
        const alert = await this.alertController.create({
          header: this.translate.instant("alert"),
          message: this.translate.instant(
            "newStore.please-fill-all-the-fields"
          ),
          backdropDismiss: false,
          buttons: ["OK"],
        });
        await alert.present();
      } else {
        this.editedStore.store_category = _.cloneDeep(this.store_category);
        const loading = await this.loadingController.create({
          message: this.translate.instant("loading"),
        });
        await loading.present();
        console.log("edited store", this.editedStore);
        for (const property in this.editedStore) {
          if (_.isString(this.editedStore[property])) {
            this.editedStore[property] = this.editedStore[property].trim();
          }
        }
        this.dataStorageService
          .editEfoodStore(
            this.editedStore.post_code,
            this.editedStore.timestamp,
            this.editedStore.store_name,
            this.editedStore.formatted_address,
            this.editedStore.store_category
          )

          .subscribe(
            async (res) => {
              loading.dismiss();
              if (!res.success) {
                const alert = await this.alertController.create({
                  header: this.translate.instant(res.comment_id),
                  backdropDismiss: false,
                  buttons: ["OK"],
                });
                await alert.present();
              } else {
                this.modalController.dismiss("edited");
              }
            },
            async (error) => {
              loading.dismiss();
              const alert = await this.alertController.create({
                header: this.translate.instant("alert"),
                message: this.translate.instant("problem_reaching_server"),
                backdropDismiss: false,
                buttons: ["OK"],
              });
              await alert.present();
              console.log("problem_reaching_server", error);
            }
          );
      }
    }
  }

  closeModal() {
    console.log("close modal called");
    this.modalController.dismiss();
  }
  ngOnDestroy() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }
}
