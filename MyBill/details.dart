import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:electromobility_flutter_application/Controllers/AppController.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Cards.dart';

class DetailPage extends StatefulWidget {

  late final AppController appController;
  late final int index;

  DetailPage(index,appController){
    this.index=index;
    this.appController = appController;
  }

  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>{
  bool downloading= false;
  String progressString='';
  String downloadedImagePath='';
  var dio = Dio();
  initState() {
    super.initState();
   }
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
    int a=widget.appController.Monthnumber;
    Dio dio = Dio();
    var b = Random().nextInt(100);
    var downloadedImagePath = '$downloadDirectory/billing$b.pdf';

    String? token = await this.widget.appController.storage.read(key: "token");
    Map<String, String> headers = {
      "Authorization": "Bearer " + (token ?? ""),
    };
    try {
      await dio.download(
        widget.appController.serverIP + ':' + widget.appController.serverPort + '/billing/billingPDF?month=$a&year=2022',
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


  @override
  Widget build(BuildContext context) {
    List months=[];
    for (var i = 0; i < 12; i++) {
      var monthNumber = (DateTime.now().month - i);
      var monthDate = DateFormat.M().parse(
          (monthNumber < 1 ? 12 - (-monthNumber) : monthNumber).toString());
      var month = DateFormat.MMMM().format(monthDate);
      months.add(month);
    }
    String result3 = widget.appController.allbillinfo[widget.index].toString();
    String result4 = result3.replaceAll('{','');
    String result5 = result4.replaceAll('[','');
    String result6 = result5.replaceAll(']','');
    String result7 = result6.replaceAll(', serial','Serial');
    String result8 = result7.replaceAll('serial','Serial');
    List<String> result = result8.split('}');
    if(result.length>2)result.removeLast();
    switch(months[widget.index]) {
      case 'January':
        widget.appController.Monthnumber=1;
        int billing=1;
        break; // The switch statement must be told to exit, or it will execute every case.
      case 'February':
        widget.appController.Monthnumber=2;
        break;
      case 'March':
        widget.appController.Monthnumber=3;
        break;
      case 'April':
        widget.appController.Monthnumber=4;
        break;
      case 'May':
        widget.appController.Monthnumber=5;
        break;
      case 'June':
        widget.appController.Monthnumber=6;
        break;
      case 'July':
        widget.appController.Monthnumber=7;
        break;
      case 'August':
        widget.appController.Monthnumber=8;
        break;
      case 'September':
        widget.appController.Monthnumber=9;
        break;
      case 'October':
        widget.appController.Monthnumber=10;
        break;
      case 'November':
        widget.appController.Monthnumber=11;
        break;
      case 'December':
        widget.appController.Monthnumber=12;
        break;
    }
      return Scaffold(
        appBar: AppBar(title: Text(months[widget.index]),
        ),
        body: Column(
          children: [
            Expanded(flex: 3,
            child: ListView(
              physics: const ClampingScrollPhysics(),
              children: [
                Card(
                  child: ListTile(
                    title: new Center(child:new Text(utf8.decode(widget.appController.userName.runes.toList()) + " " + utf8.decode(widget.appController.userSurname.runes.toList()))),
                    subtitle:new Center(child:new Text('UserID: '+widget.appController.userid.toString())),
                  ),
                ),
                Card(
                  child: ListTile(
                    title:new Center(child:new  Text(months[widget.index])),
                    subtitle:new Center(child:new Text("This month you have done "+widget.appController.Totaleachlength[widget.index].toString()+' charges')),
                  ),
                ),
                Card(
                    child: ListTile(
                      title:new Center(child:new  Text(widget.appController.Totaleachlist[widget.index].toStringAsFixed(3)+"€")),
                      subtitle:new Center(child:new Text("Total amount")),

                    )
                ),
                ElevatedButton(child: Text('Download Bill pdf'),
                    onPressed: ()  => doDownloadFile()),
                ListTile(
                  title: new Center(child: new Text('Details of your charges',style: TextStyle(fontWeight: FontWeight.bold),),),
                ),
              ],
              shrinkWrap: true,
            ),),
            Expanded(flex: 3,
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
                        MaterialPageRoute(builder: (context) => CardPage(index,widget.appController))
                    );
                  },
                );
              },
            ),)
          ],
        )
      );
  }
}