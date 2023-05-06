import { Component, OnInit, OnDestroy, Input } from "@angular/core";
import { Store } from "@ngrx/store";
import * as _ from "lodash";
import { Subscription } from "rxjs";
import { auditTime, distinctUntilChanged, map } from "rxjs/operators";
import * as fromApp from "../../store/app.reducer";
import * as appSelectors from "../../store/app.selectors";
import { DataStorageService } from "../../../app/shared/data-storage.service";
import * as Actions from "../../../app/home/store/home.actions";
import { AlertController, ModalController } from "@ionic/angular";
import { TranslateService } from "@ngx-translate/core";
import { EditServices } from "../editServices/editServices-modal.component";

@Component({
  selector: "vendor-modal-page",
  templateUrl: "./vendor-modal.component.html",
  styleUrls: ["./vendor-modal.component.scss"]
})
export class VendorModal implements OnInit, OnDestroy {
  @Input() VendorName: any;
  private subscription: any;
  public vendorSub: any;
  public storeSub: any;
  private postData: any;
  public isLoading = false;
  public competitors = [];
  private subscriptions: Subscription[] = [];
  vendors: any;
  public commonItems: any = [];
  digitalServices: any;
  filteredArray: any = null;

  constructor(
    private store: Store<fromApp.AppState>,
    public modalCtrl: ModalController,
    private dataStorageService: DataStorageService,
    private alertController: AlertController,
    private translate: TranslateService
  ) {}

  ngOnInit() {
    this.dataStorageService.fetchVendorDigitalServices().subscribe((ev: any) => {
      this.store.dispatch(new Actions.SetVendorDigitalServices(ev.digitalServices));
      console.log(ev);
      // do something with the stores data
    });

    this.subscription = this.store
      .select(appSelectors.getStoreById(this.VendorName))
      .pipe(distinctUntilChanged())
      .subscribe((state: any) => {
        if (state && !_.isEqual(this.storeSub, state)) {
          this.storeSub = _.cloneDeep(state);
        }
      });
    this.subscriptions.push(
      this.store
        .select("home")
        .pipe(distinctUntilChanged())
        .pipe(auditTime(200))
        .subscribe((state) => {
          if (state && state.vendors && !_.isEqual(this.vendors, state.vendors)) {
            this.vendors = _.cloneDeep(state.vendors);
          }
        })
    );
    this.subscription = this.store.select("home").subscribe((state) => {
      if (state && !_.isEqual(state.competitors, this.competitors)) {
        this.competitors = _.cloneDeep(state.competitors);
        console.log("competitors", state);
      }
    });
    this.vendorSub = this.storeSub;

    this.subscriptions.push(
      this.store
        .select("home")
        .pipe(distinctUntilChanged())
        .pipe(auditTime(200))
        .subscribe((state) => {
          if (
            state &&
            state.digitalServices &&
            !_.isEqual(this.digitalServices, state.digitalServices)
          ) {
            this.digitalServices = _.cloneDeep(state.digitalServices);
          }
          this.filteredArray = _.filter(this.digitalServices, {
            competitorVendor: this.vendorSub.VendorName
          });
          console.log(this.filteredArray);
        })
    );
  }

  async Save() {
    this.isLoading = true;

    if (!this.vendorSub.IsListEnabled) {
      this.vendorSub.CompetitorId = null;
    }
    this.postData = {
      VendorName: this.vendorSub.VendorName,
      Address: this.vendorSub.Address,
      TKs: this.vendorSub.TKs,
      Region: this.vendorSub.Region,
      Url: this.vendorSub.Url,
      Wholesale: this.vendorSub.Wholesale,
      Retail: this.vendorSub.Retail,
      Afm: this.vendorSub.Afm,
      Gemi: this.vendorSub.Gemi,
      IsListEnabled: this.vendorSub.IsListEnabled,
      CompetitorId: this.vendorSub.CompetitorId
    };

    this.dataStorageService.sendUpdatedVendor(this.postData).subscribe((response) => {
      console.log("Response from server:", response);

      this.store.dispatch(new Actions.UpdateVendor(this.postData));

      this.dataStorageService.fetchCompetitors().subscribe(
        async (resData) => {
          if (!resData.success) {
            const alert = await this.alertController.create({
              header: this.translate.instant("alert"),
              message: this.translate.instant(resData.comment_id),
              backdropDismiss: false,
              buttons: ["OK"]
            });
            await alert.present();
          }
          this.isLoading = false;
          this.modalCtrl.dismiss();
        },
        async (error) => {
          const alert = await this.alertController.create({
            header: this.translate.instant("alert"),
            message: this.translate.instant("problem_reaching_server"),
            backdropDismiss: false,
            buttons: ["OK"]
          });
          await alert.present();
          console.log("problem_reaching_server", error);
        }
      );
    });
  }



  async editServices(vendor:any) {
    const modal = await this.modalCtrl.create({
      component: EditServices,
      cssClass: "editServicesModal",
      backdropDismiss: false,
      componentProps: {
        VendorName: vendor
      }
    });
    return await modal.present();
  }

  check() {
    const selectedItems = _.map(this.vendors, "CompetitorId");
    const competitorNames = _.map(this.competitors, "id");
    console.log("Common Items:", competitorNames);

    this.commonItems = _.intersection(selectedItems, competitorNames);
    console.log("Common Items:", this.commonItems);
  }

  ngOnDestroy() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }
}
