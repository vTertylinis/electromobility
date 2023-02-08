import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../Controllers/AppController.dart';
import '../Evse/Evse.dart';
import '../Panels/EvsePanel.dart';
import 'dart:convert';
// This is the class for List Page //


class ListPage  extends StatefulWidget {
  late final AppController appController;
  ListPage(appController){
    this.appController = appController;
  }

  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  late double unitHeightValue;
  final myController = TextEditingController();
  bool firstTime = false;
  String evseSearchField = "";
  Evse evse = new Evse(evseID: 0, friendlyName: "", registrationStatus:"", street: "", streetNumber: "", region: "", lat: 0.0, lng: 0.0, connectorList: [], cpSerial: "", img: "", distance: 0.0);
  late List<EvsePanel> evsePanels = [new EvsePanel(evse: evse, appController: widget.appController, hide: true, available: stationAvailability.available, isMapPanel: false,)];
  late TextField searchTextField = TextField(
    controller: myController,
    decoration: InputDecoration(
      border: InputBorder.none,
      hintText: 'Search',
      fillColor: Colors.white,
    ),
  );

  final controller = ScrollController();
  List<String> items = [];
  bool hasMore = true;
  int page = 1;
  bool isLoading = false;

  @override
  void initState(){
    super.initState();

    fetch();

    controller.addListener(() {
      if (controller.position.maxScrollExtent == controller.offset) {
        fetch();
      }
    });
  }

  @override
  void dispose() {
    myController.dispose();
    controller.dispose();
    super.dispose();
  }

  void refreshEvsePanels() async{
    const refreshSeconds = const Duration(seconds: 5);
    Timer.periodic(refreshSeconds, (Timer t) {
      if(!mounted) {
        t.cancel();
        return;
      }
      showEvsePanels();
    });
  }
  void showEvsePanels() async{
    // Old native sorting
    // if(widget.appController.userContract == null){
    //   tempEvses.sort((a, b) {
    //     int nameComp = a.sort_availability.compareTo(b.sort_availability);
    //     if (nameComp == stationAvailability.available.index) {
    //       return a.distance.compareTo(b.distance); // '-' for descending
    //     }
    //     return nameComp;
    //   });
    // }    
    setState(() {
      if (evseSearchField.isEmpty){
        int i = 0;
        if (tempEvses.length != 0){
          evsePanels.clear();
          while (i < tempEvses.length){
            evsePanels.add(new EvsePanel(evse: tempEvses[i], appController: widget.appController, hide: false, available: tempEvses[i].availability, isMapPanel: false,));
            i++;
          }
        }
      }
      else{
        int i = 0;
        if (tempEvses.length != 0){
          evsePanels.clear();
          while (i < tempEvses.length){
            if (containsIgnoreCase(tempEvses[i].friendlyName, evseSearchField))
              evsePanels.add(new EvsePanel(evse: tempEvses[i], appController: widget.appController, hide: false, available: tempEvses[i].availability, isMapPanel: false,));
            i++;
          }
        }
      }
    });
  }
  List<Evse> tempEvses = [];

  Future fetch() async {
    String? token = await widget.appController.storage.read(key: "token");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer " + (token ?? ""),
    };

    if (isLoading) return;
    isLoading = true;

    const limit = 15;
    final url = Uri.parse(widget.appController.serverIP.toString()+':'+widget.appController.serverPort.toString()+'/evse/getEvsesPaged?page=$page&pageLimit=$limit' +
    (widget.appController.userContract == null ? '&orderby=availability' : '&orderby=distance') +
        (this.widget.appController.currentLocation != null ? '&lat=' +
          this.widget.appController.currentLocation!.latitude.toString() + '&lon=' +
          this.widget.appController.currentLocation!.longitude.toString() : '' ));

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List newItems = json.decode(response.body)["results"];

        page++;
        isLoading = false;

        if (newItems.length <limit) {
          hasMore = false;
        }
      List<Evse> result = [];
      for (var items in newItems) {
        final evseID = items['evseID'];
        final friendlyName = items['friendlyName'];
        final registrationStatus = items['registrationStatus'];
        final street = items['street'];
        final streetNumber = items['streetNumber'];
        final region = items['region'];
        final lat = items['latitude'] ?? 0.0;
        final lng = items['longitude'] ?? 0.0;
        final connectorList = items['connectorWSList'];
        final cpSerial = items['cpSerial'];
        final img = items['img'];
        final distance = items['distance'];
        if (registrationStatus == 'Accepted') {
          result.add(new Evse(
              evseID: evseID,
              friendlyName: friendlyName,
              registrationStatus: registrationStatus,
              street: street,
              streetNumber: streetNumber,
              region: region,
              lat: lat,
              lng: lng,
              connectorList: connectorList,
              cpSerial: cpSerial,
              img: img,
              distance: distance ?? 0.0));
        }
      }
      tempEvses.addAll(result);
        for(int i=0 ; i<tempEvses.length; i++  ){
          this.tempEvses[i].calculateAvailability();
          this.tempEvses[i].isEvseFavorite(widget.appController.favoritesList);
          this.tempEvses[i].storePlugCounters();
        }
        showEvsePanels();
    }
  }

  Future refresh() async{
    setState(() {
      isLoading = false;
      hasMore =true;
      page = 0;
      tempEvses.clear();
    });
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    if(!firstTime){
      this.unitHeightValue = widget.appController.queryData.size.height * 0.001;
      showEvsePanels();
      //refreshEvsePanels();
      firstTime = true;
    }

    return  SizedBox(
        height: widget.appController.queryData.size.height,
        width : widget.appController.queryData.size.width,

        child: Column(
            children: [
              Container(
                height: widget.appController.queryData.size.height/12,
                width: widget.appController.queryData.size.width * (9/10),
                margin: EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                    color: widget.appController.themeController.appWhiteLightColor,
                    boxShadow: [
                      BoxShadow(
                        color: widget.appController.themeController.appGreyLightColor.withOpacity(0.6),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: Offset(0, 2), // changes position of shadow
                      ),
                    ],
                    shape: BoxShape.rectangle,
                    border: Border.all(
                      color: Colors.transparent,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                child:Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:[
                      Container(
                        width: widget.appController.queryData.size.width * (7/10),
                        child: searchTextField,
                      ),
                      Container(
                        child: IconButton(
                          color: widget.appController.themeController.appBlackDeepColor,
                          tooltip: 'Search',
                          icon: const Icon(Icons.search),
                          iconSize: 32 * this.unitHeightValue,
                          onPressed: () {
                            fetch();
                            this.evseSearchField = myController.text;
                            showEvsePanels();
                          },
                        ),
                      ),
                    ]
                ),
              ),
              Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetch,
                    child: ListView.separated(
                        separatorBuilder: (context, index) => Divider(),
                        controller: controller,
                        padding: const EdgeInsets.all(8),
                        itemCount: evsePanels.length + 1,
                        itemBuilder: (context, index) {
                          if (index < evsePanels.length) {
                            return evsePanels[index];
                          } else {
                            return  Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: hasMore
                                    ? const CircularProgressIndicator()
                                    : const Text('No more data to load'),
                              ),
                            );
                          }
                        }
                    ),
                  )
              )
            ]
        )
    );
  }
  bool containsIgnoreCase(String str1, String str2) {
    return str1.toLowerCase().contains(str2.toLowerCase());
  }

}