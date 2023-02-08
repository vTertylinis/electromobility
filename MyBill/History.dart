import 'package:flutter/material.dart';
import 'package:electromobility_flutter_application/Controllers/AppController.dart';
import 'package:intl/intl.dart';
import 'details.dart';

class Historyview extends StatefulWidget {

  late final AppController appController;

  Historyview(appController){
    this.appController = appController;
  }

  _HistoryviewState createState() => _HistoryviewState();
}

class _HistoryviewState extends State<Historyview> {
  void monthssort(){
    for (var i = 0; i < 12; i++) {
      var monthNumber = (DateTime.now().month - i);
      var monthDate = DateFormat.M().parse(
          (monthNumber < 1 ? 12 - (-monthNumber) : monthNumber).toString());
      var year = DateTime.now().month - i < 1
          ? DateTime.now().year - 1
          : DateTime.now().year;
      var month = DateFormat.MMMM().format(monthDate);
      months.add('$year $month');
    }
  }
List months=[];
  initState() {
    monthssort();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My History"),
      ),
      body: _buildListView(context) ,


    );
  }
ListView _buildListView(BuildContext context){

    return ListView.builder(itemCount: months.length,
    itemBuilder: (_, index){
      return ListTile(
        title: Text(months[index]),
        subtitle: Text(widget.appController.Totaleachlist[index].toStringAsFixed(3)+'€'),
        leading: Icon(Icons.account_balance_wallet_rounded),
        trailing: Icon(Icons.arrow_forward),
        onTap: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailPage(index,widget.appController))
          );
        },
      );
    },
    );
}

}
