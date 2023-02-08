import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:electromobility_flutter_application/Controllers/AppController.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../Evse/EvseBill.dart';

class CurrentCardPage  extends StatefulWidget {
  late final AppController appController;
  late final int index;
  CurrentCardPage(index,appController){
    this.index=index;
    this.appController = appController;
  }

  @override
  _CurrentCardPageState createState() => _CurrentCardPageState();
}
class _CurrentCardPageState extends State<CurrentCardPage> {
  final storage = new FlutterSecureStorage();
  List cardBills=[];
  double sum=0;


  @override
  void initState(){
    super.initState();

    fetch();
  }

  Future<List<Evsebill>> fetch() async {
    String tertis=widget.appController.cards[widget.index];
    List numbers =
    ['1', '2', '3', '4', '5','6','7','8','9','10','11','12'];
    var now = new DateTime.now();
    int current_num = now.month;
    var twranumb=(numbers[current_num-1]);
    String? token = await this.storage.read(key: "token");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer " + (token ?? ""),
    };

    final response = await http.get(Uri.parse(
        widget.appController.serverIP + ':' + widget.appController.serverPort +
            '/user/contractedChargeTransactionsByCard?month=$twranumb&year=2022&card=$tertis'),
        headers: headers);
    if (response.statusCode == 200) {
      setState(() {
        cardBills = jsonDecode(response.body)["cardBills"] as List;
      });
      var data = cardBills.map((e) => e["total"]).toList();
      sum = data.reduce((value, current) => value + current);
      return cardBills.map((e) => Evsebill.fromJson(e)).toList();
    }
    else{
      throw Exception('Failed to load Bills');
    }

  }


  @override
  Widget build(BuildContext context) {
    final columns = ['Charging Point','Duration','Value','Start at'];
    return Scaffold(
        appBar: AppBar(title: Text(widget.appController.cards[widget.index]),
        ),
        body: Column(
          children: [
            Expanded(flex: 1,
              child: ListView(
                physics: const ClampingScrollPhysics(),
                children: [
                  Card(
                      child: ListTile(
                        title:new Center(child:new  Text(sum.toStringAsFixed(3)+"€")),
                        subtitle:new Center(child:new Text("Total amount")),

                      )
                  ),
                  ListTile(
                    title: new Center(child: new Text('Details of your charges',style: TextStyle(fontWeight: FontWeight.bold),),),
                  ),
                ],
                shrinkWrap: true,
              ),),
            Expanded(flex: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: getColumns(columns),
                      showCheckboxColumn: false,
                      dividerThickness: 5,
                      columnSpacing: 20,
                      showBottomBorder: true,
                      rows: cardBills.map((e) => DataRow(cells: [
                        DataCell(Text(e['chargingPoint'].toString())),
                        DataCell(Text((e['hours'].toString()+'h '+e['minutes'].toString()+'m').toString())),
                        DataCell(Text(e['total'].toString()+' €')),
                        DataCell(Text((DateTime.parse(e['start'].toString()).toLocal().toString()).replaceAll(".333", ""))),
                      ],onSelectChanged: (newValue){
                        print('row 1 pressed');
                      },)).toList(),
                    ),
                  ),
                )

            )],
        )
    );
  }

  List<DataColumn> getColumns(List<String>columns)=> columns.map((String column)=> DataColumn(
    label: Text(column),
  )).toList();


}