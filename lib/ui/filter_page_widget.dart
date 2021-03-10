import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:scanbot_sdk/common_data.dart' as c;
import 'package:scanbot_sdk/scanbot_encryption_handler.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart';
import 'package:scanbot_sdk_example_flutter/ui/progress_dialog.dart';
import 'package:scanbot_sdk_example_flutter/ui/utils.dart';

class PageFiltering extends StatelessWidget {
  final c.Page _page;

  PageFiltering(this._page);

  @override
  Widget build(BuildContext context) {
    imageCache.clear();
    var filterPreviewWidget = FilterPreviewWidget(_page);
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            GestureDetector(
              onTap: () {
                filterPreviewWidget.applyFilter();
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text('APPLY',
                      style: TextStyle(inherit: true, color: Colors.black)),
                ),
              ),
            ),
          ],
          iconTheme: IconThemeData(
            color: Colors.black, //change your color here
          ),
          backgroundColor: Colors.white,
          title: const Text('Filtering',
              style: TextStyle(inherit: true, color: Colors.black)),
        ),
        body: filterPreviewWidget);
  }
}

// ignore: must_be_immutable
class FilterPreviewWidget extends StatefulWidget {
  final c.Page page;
  FilterPreviewWidgetState filterPreviewWidgetState;

  FilterPreviewWidget(this.page) {
    filterPreviewWidgetState = FilterPreviewWidgetState(page);
  }

  void applyFilter() {
    filterPreviewWidgetState.applyFilter();
  }

  @override
  State<FilterPreviewWidget> createState() {
    return filterPreviewWidgetState;
  }
}

class FilterPreviewWidgetState extends State<FilterPreviewWidget> {
  c.Page page;
  Uri filteredImageUri;
  c.ImageFilterType selectedFilter;

  FilterPreviewWidgetState(this.page) {
    filteredImageUri = page.documentImageFileUri;
    selectedFilter = page.filter ?? c.ImageFilterType.NONE;
  }

  @override
  Widget build(BuildContext context) {
    var file = File.fromUri(filteredImageUri);
    var imageData =
    ScanbotEncryptionHandler.getDecryptedDataFromFile(filteredImageUri);
    var image = FutureBuilder(
        future: imageData,
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
          if (snapshot.data != null) {
            var image = Image.memory(snapshot.data);
            return Center(child: image);
          } else {
            return Container();
          }
        });
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        buildContainer(image),
        Text('Select filter',
            style: TextStyle(
                inherit: true,
                color: Colors.black,
                fontStyle: FontStyle.normal)),
        for (var filter in c.ImageFilterType.values)
          RadioListTile(
            title: titleFromFilterType(filter),
            value: filter,
            groupValue: selectedFilter,
            onChanged: (value) {
              previewFilter(page, value);
            },
          ),
      ],
    );
  }

  Container buildContainer(Widget image) {
    return Container(
      height: 400,
      padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Center(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          child: Center(child: image),
        ),
      ),
    );
  }

  Text titleFromFilterType(c.ImageFilterType filterType) {
    return Text(
      filterType.toString().replaceAll('ImageFilterType.', ''),
      style: TextStyle(
        inherit: true,
        color: Colors.black,
        fontStyle: FontStyle.normal,
      ),
    );
  }

  Future<void> applyFilter() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    final dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    dialog.style(message: 'Processing');
    dialog.show();
    try {
      final updatedPage =
          await ScanbotSdk.applyImageFilter(page, selectedFilter);
      await dialog.hide();
      Navigator.of(context).pop(updatedPage);
    } catch (e) {
      await dialog.hide();
      print(e);
    }
  }

  Future<void> previewFilter(c.Page page, c.ImageFilterType filterType) async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      final uri =
          await ScanbotSdk.getFilteredDocumentPreviewUri(page, filterType);
      setState(() {
        selectedFilter = filterType;
        filteredImageUri = uri;
      });
    } catch (e) {
      print(e);
    }
  }
}
