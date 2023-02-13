import 'ShowBookingsPage.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../Panels/SessionOrBookingPanel.dart';
import '../../Controllers/AppController.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CalendarBookings extends StatefulWidget {
  late AppController appController;
  CalendarBookings(appController){
    this.appController = appController;
  }

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".


  @override
  _CalendarBookingsState createState() => _CalendarBookingsState();
}
class _CalendarBookingsState extends State<CalendarBookings> {
  DateRangePickerController _datePickerController = DateRangePickerController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text('My Calendar'),
        backgroundColor: this.widget.appController.themeController.appDeepBlueColor,
        leading: IconButton(
          tooltip: 'Back',
          alignment: Alignment.centerLeft,
          icon: (widget.appController.deviceIsAndroid) ? const Icon(Icons.arrow_back) : const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SfDateRangePicker(
        selectionColor: widget.appController.themeController.appDeepBlueColor,
        todayHighlightColor: widget.appController.themeController.appDeepBlueColor,
        navigationDirection: DateRangePickerNavigationDirection.vertical,
        navigationMode: DateRangePickerNavigationMode.scroll,
        view: DateRangePickerView.month,
        enableMultiView: true,
        monthViewSettings: DateRangePickerMonthViewSettings(firstDayOfWeek: 6,
            specialDates:(widget.appController.startdatetime)),
        monthCellStyle: DateRangePickerMonthCellStyle(
          specialDatesDecoration: BoxDecoration(
              color: widget.appController.themeController.appDeepGreenColor,
              border: Border.all(color: const Color(0xFF2B732F), width: 1),
              shape: BoxShape.circle),
          blackoutDateTextStyle: TextStyle(color: Colors.white, decoration: TextDecoration.lineThrough),
          specialDatesTextStyle: const TextStyle(color: Colors.white),
        ),
        onSelectionChanged: _onSelectionChanged,
        controller: _datePickerController,
        onCancel: () {
          _datePickerController.selectedRanges = null;
        },
      ),
    );
  }

  void _onSelectionChanged(
      DateRangePickerSelectionChangedArgs dateRangePickerSelectionChangedArgs) {
    print(dateRangePickerSelectionChangedArgs.value);
  }
}
