import { Component, OnInit, OnDestroy, EventEmitter, Output, Input } from "@angular/core";
import { ModalController, AlertController } from "@ionic/angular";
import * as _ from "lodash";
import { HttpBackend, HttpClient, HttpEventType, HttpHeaders } from "@angular/common/http";
import { NgxFileDropEntry, FileSystemFileEntry, FileSystemDirectoryEntry } from "ngx-file-drop";
import { DataStorageService } from "src/app/shared/data-storage.service";
import { catchError, retry } from "rxjs/operators";
import { v4 as uuidv4 } from "uuid";
import { UploadHistoryDigitalServices } from "../uploadHistoryDigitalServices/uploadHistoryDigitalServices-modal.component";
import * as HomeActions from "../../home/store/home.actions";
import { Store } from "@ngrx/store";
import * as fromApp from "../../store/app.reducer";

@Component({
  selector: "digitalServicesDragAndDrop-modal-page",
  templateUrl: "./digitalServicesDragAndDrop-modal.component.html",
  styleUrls: ["./digitalServicesDragAndDrop-modal.component.scss"]
})
export class DigitalServicesDragAndDrop implements OnInit, OnDestroy {
  public data;
  public fileName;
  public signedTimestamp;
  @Input() store;
  public contentType;
  public fileType;
  public isLoading: boolean;
  public loading = false;
  public uploadProgressValue: any;
  private http: HttpClient;
  public signedUrl;
  public spinner = false;
  public files: NgxFileDropEntry[] = [];
  @Output() linkEvent = new EventEmitter();
  @Output() linkEventEdit = new EventEmitter();
  public buttonDisabled = false;
  constructor(
    private dataStorageService: DataStorageService,
    public modalCtrl: ModalController,
    private alertController: AlertController,
    private Store: Store<fromApp.AppState>,
    handler: HttpBackend
  ) {
    this.http = new HttpClient(handler);
  }

  public dropped(files: NgxFileDropEntry[]) {
    this.spinner = true;
    this.files = files;
    for (const droppedFile of files) {
      // Is it a file?
      if (droppedFile.fileEntry.isFile) {
        const fileEntry = droppedFile.fileEntry as FileSystemFileEntry;
        fileEntry.file((file: File) => {
          // Here you can access the real file
          console.log(droppedFile.relativePath, file);
          // Call handleCsvUpload function with necessary parameters
          let filetype: any;
          if (file.type === "text/csv") {
            filetype = "csv";
          } else {
            console.log("only-csv-files-is-allowed");
            this.presentAlert();
            return;
          }
          let fileName = uuidv4() + "." + filetype;
          let directory = "digital-services-csvs-folder/" + fileName;

          this.dataStorageService
            .handleCsvUpload(fileName, directory)
            .pipe(
              catchError((err) => {
                this.presentErrorAlert("Error while uploading csv");
                return null;
              })
            )
            .subscribe((res: any) => {
              if (res.success) {
                console.log(res, "195");
                this.data = res.data;
                console.log("the data", this.data);
                this.fileName = this.data.fileName;
                this.fileType = this.data.fileType;
                this.signedUrl = this.data.signedUrl;
                this.signedTimestamp = this.data.signed_timestamp;
                this.contentType = this.data.contentType;
                console.log(
                  this.fileName,
                  this.fileType,
                  this.signedUrl,
                  this.signedTimestamp,
                  this.contentType,
                  "90"
                );
                console.log(this.fileType);
                this.uploadCsvData(file, this.signedUrl, this.contentType, this.fileName);
              } else if (!res || !res.success) {
                console.log("errrrrr");
                if (res.comment_id) {
                  this.presentErrorAlert("error");
                }
                this.loading = false;
              }
            });
        });
      } else {
        // It was a directory (empty directories are added, otherwise only files)
        const fileEntry = droppedFile.fileEntry as FileSystemDirectoryEntry;
        console.log(droppedFile.relativePath, fileEntry);
      }
    }
  }

  public fileOver(event) {
    console.log(event);
  }

  public fileLeave(event) {
    console.log(event);
  }

  async uploadCsvData(file, signed_url, fileType, fileName) {
    console.log("index");
    console.log(fileType);
    this.http
      .put(signed_url, file, {
        reportProgress: true,
        observe: "events",
        headers: new HttpHeaders({
          "Content-Type": fileType
        })
      })
      .subscribe({
        next: (events) => {
          if (events.type === HttpEventType.UploadProgress) {
            this.uploadProgressValue =
              parseFloat(Math.floor((events.loaded / events.total) * 100).toString()) / 100;
          } else if (events.type === HttpEventType.Response) {
            console.log("uploadFiles response", events);
            if (events.status === 200) {
              console.log("complete");
              this.loading = false;
              console.log("loading", this.uploadProgressValue);
              this.linkEvent.emit(
                "https://d3d6gt28pek4xp.cloudfront.net/advertising-csv/" + fileName
              );
              this.linkEventEdit.emit(
                "https://d3d6gt28pek4xp.cloudfront.net/advertising-csv/" + fileName
              );
              this.modalCtrl.dismiss();
            } else {
              console.log("failed");
              this.loading = false;
            }
          }
        },
        error: async (error) => {
          console.log("error loading", error);
          this.isLoading = false;
        },
        complete: () => {}
      });
  }

  async presentErrorAlert(errorMsg) {
    const alert = await this.alertController.create({
      cssClass: "my-custom-class",
      header: "error",

      message: errorMsg,
      buttons: ["OK"]
    });

    await alert.present();
  }

  async presentAlert() {
    const alert = await this.alertController.create({
      header: "Alert",
      message: "Only csv files is allowed",
      buttons: ["OK"]
    });

    await alert.present();
  }

  async uploadhistory() {
    const modal = await this.modalCtrl.create({
      component: UploadHistoryDigitalServices,
      cssClass: "uploadhistoryDigitalServices",
      backdropDismiss: false,
      componentProps: {}
    });
    await modal.present();
    modal.onDidDismiss().then(() => {
      this.Store.dispatch(new HomeActions.ClearCsvsAction(_.cloneDeep()));
    });
  }

  ngOnInit() {}

  ngOnDestroy() {}
}
