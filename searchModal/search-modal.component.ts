import { Component, OnInit, OnDestroy, EventEmitter, Output } from "@angular/core";
import { ModalController, AlertController } from "@ionic/angular";
import { DataStorageService } from "../../shared/data-storage.service";
import { TranslateService } from "@ngx-translate/core";
import { Store } from "@ngrx/store";
import * as fromApp from "../../store/app.reducer";
import * as _ from "lodash";
import { Observable, Subscription } from "rxjs";
import { auditTime, distinctUntilChanged, map } from "rxjs/operators";
import { HttpClient } from "@angular/common/http";
import * as LoyaltySystemActions from "../../../app/home/store/home.actions";
import { VendorModal } from "../vendorDetails/vendor-modal.component";
import { DragAndDrop } from "../dragAndDropCsvModal/dragAndDrop-modal.component";
import { DigitalServices } from "../digitalServicesModal/digitalServices-modal.component";

@Component({
  selector: "search-modal-page",
  templateUrl: "./search-modal.component.html",
  styleUrls: ["./search-modal.component.scss"]
})
export class SearchModal implements OnInit, OnDestroy {
  private subscriptions: Subscription[] = [];
  public vendors$: Observable<any[]>;
  vendors: any;
  searchTerm: string = "";
  showCompetitors = false;

  constructor(
    private store: Store<any>,
    public modalCtrl: ModalController,
    private alertController: AlertController,
    private dataStorageService: DataStorageService,
    private translate: TranslateService,
    private modalController: ModalController,
    private http: HttpClient
  ) {
    this.vendors$ = this.store.select((state) => state.vendors);
  }

  async vendorDetails(vendor: any) {
    const modal = await this.modalController.create({
      component: VendorModal,
      cssClass: "vendorModal",
      componentProps: {
        VendorName: vendor.VendorName
      }
    });
    await modal.present();
    modal.onDidDismiss().then(() => {
      this.store.dispatch(new LoyaltySystemActions.ClearVendorDigitalServicesAction(_.cloneDeep()));
    });
  }

  async dragAndDrop() {
    const modal = await this.modalController.create({
      component: DragAndDrop,
      cssClass: "dragAndDropModal",
      backdropDismiss: false,
      componentProps: {}
    });
    return await modal.present();
  }

  async digitalServices() {
    const modal = await this.modalController.create({
      component: DigitalServices,
      cssClass: "digitalServices",
      backdropDismiss: false,
      componentProps: {}
    });
    await modal.present();
    modal.onDidDismiss().then(() => {
      this.store.dispatch(new LoyaltySystemActions.ClearVendorDigitalServicesAction(_.cloneDeep()));
    });
  }

  ngOnInit() {
    this.dataStorageService.getStores().subscribe((ev: any) => {
      this.store.dispatch(new LoyaltySystemActions.SetVendors(ev.vendors));
      console.log(ev);
      // do something with the stores data
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
  }

  closeModal() {
    this.modalController.dismiss();
  }

  ngOnDestroy() {
    this.subscriptions.forEach((sub) => sub.unsubscribe());
    this.vendors = [];
  }
}
