import { Component, OnInit, OnDestroy } from "@angular/core";
import { ModalController } from "@ionic/angular";
import * as _ from "lodash";
import { DataStorageService } from "src/app/shared/data-storage.service";
import * as action from "../../../app/home/store/home.actions";
import { Observable, Subscription } from "rxjs";
import { Store } from "@ngrx/store";
import { auditTime, distinctUntilChanged } from "rxjs/operators";
import * as fromApp from "../../store/app.reducer";
import * as HomeActions from "../../home/store/home.actions";

@Component({
  selector: "uploadHistoryDigitalServices-modal-page",
  templateUrl: "./uploadHistoryDigitalServices-modal.component.html"
})
export class UploadHistoryDigitalServices implements OnInit, OnDestroy {
  public csvsDigital$: Observable<any[]>;
  private subscriptions: Subscription[] = [];
  public csvsDigital: any = null;

  constructor(
    public modalCtrl: ModalController,
    private dataStorageService: DataStorageService,
    private store: Store<fromApp.AppState>
  ) {}

  closemodal() {
    this.modalCtrl.dismiss();
  }

  ngOnInit() {
    console.log("UploadHistory created");
    this.dataStorageService.csvDigitalServicesUploadHistory().subscribe((ev: any) => {
      const transformedContents = ev.contents.map((item) => ({
        ...item,
        Key: item.Key.replace("digital-services-csvs-folder/", "")
      }));
      this.store.dispatch(new action.CsvUploadHistoryDigital(transformedContents));
      console.log(transformedContents);
      // do something with the stores data
    });

    this.subscriptions.push(
      this.store
        .select("home")
        .pipe(distinctUntilChanged())
        .pipe(auditTime(200))
        .subscribe((state) => {
          if (state && state.csvsDigital && !_.isEqual(this.csvsDigital, state.csvsDigital)) {
            this.csvsDigital = _.cloneDeep(state.csvsDigital);
          }
        })
    );
  }

  refresh() {
    this.store.dispatch(new HomeActions.ClearCsvsActionDigital(_.cloneDeep()));
    this.csvsDigital = null;
    this.dataStorageService.csvDigitalServicesUploadHistory().subscribe((ev: any) => {
      const transformedContents = ev.contents.map((item) => ({
        ...item,
        Key: item.Key.replace("digital-services-csvs-folder/", "")
      }));
      this.store.dispatch(new action.CsvUploadHistoryDigital(transformedContents));
      console.log(transformedContents);
      // do something with the stores data
    });
  }

  ngOnDestroy() {
    this.csvsDigital = null;
    this.subscriptions.forEach((sub) => sub.unsubscribe());
    console.log("UploadHistory destroyed");
  }
}
