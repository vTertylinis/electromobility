import 'dart:convert';
import 'dart:math';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:electromobility_flutter_application/Controllers/AppController.dart';
import 'Cards.dart';
import 'CurrentMonthCard.dart';
import 'History.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class MyBillPage extends StatefulWidget {

  late final AppController appController;

  MyBillPage(appController){
    this.appController = appController;
  }

  _MyBillPageState createState() => _MyBillPageState();
}

class _MyBillPageState extends State<MyBillPage>{
  bool downloading= false;
  String progressString='';
  String downloadedImagePath='';
  var dio = Dio();
  int month=0;
  String twramonth='';
  int _counter = 0;
  var b=0;
  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('My eBill'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Download Completed'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future < bool > getStoragePremission() async {
    return await Permission.storage.request().isGranted;
  }
  Future < String > getDownloadFolderPath() async {
    return await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS);
  }
  Future downloadFile(String downloadDirectory) async {
    var monthNumber = (DateTime.now().month);
    var monthi = (monthNumber < 1 ? 12 - (-monthNumber) : monthNumber);
    Dio dio = Dio();
    b = Random().nextInt(100);
    var downloadedImagePath = '$downloadDirectory/lastbilling$b.pdf';
    String? token = await this.widget.appController.storage.read(key: "token");
    Map<String, String> headers = {
      "Authorization": "Bearer " + (token ?? ""),
    };
    try {
      await dio.download(
        widget.appController.serverIP + ':' + widget.appController.serverPort + '/billing/billingPDF?month=$monthi&year=2022',
          downloadedImagePath,
          onReceiveProgress: (rec, total) {
            print("REC: $rec , TOTAL: $total");
            setState(() {
              downloading = true;
              progressString = ((rec / total) * 100).toStringAsFixed(0) + "%";
            });
          },
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          }),
      );
    } catch (e) {
      print(e);
    }

    // Delay to show that the download is complete
    await Future.delayed(const Duration(seconds: 3));

    return downloadedImagePath;
  }

  /// Do download by user's click
  Future < void > doDownloadFile() async {
    if (await getStoragePremission()) {
      String downloadDirectory = await getDownloadFolderPath();
      await downloadFile(downloadDirectory).then((imagePath) {
        _diplayImage(imagePath);
        _showMyDialog();
      });
    }
  }

  /// Display image after download completed
  void _diplayImage(String downloadDirectory ) {
    setState(() {
      downloading = false;
      progressString = "COMPLETED";
      downloadedImagePath = downloadDirectory;
    });
  }
  /*void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  Future<void> SaveData() async {

    Directory? directory;
    directory = await getApplicationDocumentsDirectory();

    File saveFile = File(directory.path+ "nameofFile.pdf");

    var dio = Dio();
    String fileUrl = "https://everywhere-dev.iccs.gr:18081/billing/billingPDF?month=8&year=2022&cardID=56";
    String? token = await this.widget.appController.storage.read(key: "token");
    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.headers['ccept'] = 'application/json';
    dio.options.headers['Authorization'] = "Bearer " + (token ?? "");
    try {
      await dio.download(fileUrl, saveFile.path, onReceiveProgress: (received,total) {

        int progress = (((received / total) * 100).toInt());

        print(progress);

        final url = saveFile.path;

        OpenFile.open(url);


      });


    } on DioError catch (e) {

      throw Exception(e);

    }

  }

  final pdfUrl =
      "https://everywhere-dev.iccs.gr:18081/billing/billingPDF?month=8&year=2022&cardID=56";
  Future download2(Dio dio, String pdfUrl, String savePath) async {
    String? token = await this.widget.appController.storage.read(key: "token");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer " + (token ?? ""),
    };
    try {
      Response response = await dio.get(
        pdfUrl,
        onReceiveProgress: showDownloadProgress,
        //Received data with List<int>
        options: Options(
          headers: headers,
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) {
              return status! < 500;
            }),
      );
      print(response.headers);
      File file = File(savePath);
      var raf = file.openSync(mode: FileMode.write);
      // response.data is List<int> type
      raf.writeFromSync(response.data);
      await raf.close();
    } catch (e) {
      print(e);
    }
  }
  void showDownloadProgress(received, total) {
    if (total != -1) {
      print((received / total * 100).toStringAsFixed(0) + "%");
    }
  }*/


  initState() {
    super.initState();
    List months =
    ['January', 'February', 'March', 'April', 'May','June','July','August','September','October','November','December'];
    var nowmonth = new DateTime.now();
    int current_mon = nowmonth.month;
    twramonth=(months[current_mon-1]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("My Bill"),
        ),
        body:Column(children: [
          Expanded(flex: 3,child:
          ListView(
            physics: const ClampingScrollPhysics(),
            children: [
              Card(
                  child: ListTile(
                    title:new Center(child:new Text(utf8.decode(widget.appController.userName.runes.toList()) + " " + utf8.decode(widget.appController.userSurname.runes.toList()))),
                    subtitle:new Center(child:new Text('UserID: '+widget.appController.userid.toString())),
                  )
              ),
              Card(
                child: ListTile(
                  title:new Center(child:new  Text(twramonth)),
                  subtitle:new Center(child:new Text("This month you have done "+widget.appController.resulttotal.toString()+' charges')),
                ),
              ),
              Card(
                  child: ListTile(
                    title:new Center(child:new  Text(widget.appController.sum.toStringAsFixed(3)+"€")),
                    subtitle:new Center(child:new Text("Total amount")),

                  )
              ),
              ElevatedButton(child: Text('Download Bill pdf'),
                  onPressed: ()  => doDownloadFile())
              ,
              ElevatedButton(child: Text('View history'),
                  onPressed: () => {

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => new Historyview(widget.appController)),
                    )
                  })
            ],
            shrinkWrap: true,
          ),),Expanded(flex: 3,
          child: ListView.builder(itemCount: widget.appController.cards.length,
            itemBuilder: (_, index){
              return ListTile(
                title: Text(widget.appController.cards[index]),
                subtitle: Text('Card'),
                leading: Icon(Icons.account_balance_wallet_rounded),
                trailing: Icon(Icons.arrow_forward),
                onTap: (){
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CurrentCardPage(index,widget.appController))
                  );
                },
              );
            },
          ),)
        ],)
    );
  }
}
