import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter with VGS Collect/Show SDK'),
    );
  }
}

typedef void CardCollectFormCallback(CardCollectFormController controller);

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const COLLECT_FORM_VIEW_TYPE = 'card-collect-form-view';
const SHOW_FORM_VIEW_TYPE = 'card-show-form-view';

const CARD_TOKEN_KEY = 'cardNumber';
const DATE_TOKEN_KEY = 'expDate';

const COLLECT_ERROR_CODE_KEY = 'collect_error_code';
const COLLECT_ERROR_MESSAGE_KEY = 'collect_error_message';

const SHOW_SUCCESS_CODE_KEY = 'show_status_code';
const SHOW_ERROR_CODE_KEY = 'show_error_code';
const SHOW_ERROR_MESSAGE_KEY = 'show_error_message';

class _MyHomePageState extends State<MyHomePage> {
  CardCollectFormController collectController;
  TextEditingController textEditingController = TextEditingController();
  PageController pageController = PageController();

  String cardToken;
  String dateToken;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Color(0xff3c4c5d),
        ),
        body: PageView(
          controller: pageController,
          children: [
            _page1(),
            _page2(),
          ],
        ),
      ),
    );
  }

  Widget _page1() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextFormField(
            controller: textEditingController,
            keyboardType: TextInputType.number,
          ),
          ElevatedButton(
            onPressed: () => pageController.nextPage(duration: Duration(milliseconds: 200), curve: Curves.easeIn),
            child: Text('Avançar'),
          ),
        ],
      ),
    );
  }

  Widget _page2() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 50,
            width: double.infinity,
            child: _cardCollect(),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _collectButton(),
              ),
              Text("Powered by VGS Collect SDK", style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardCollect() {
    final Map<String, dynamic> creationParams = <String, dynamic>{};
    return PlatformViewLink(
      viewType: COLLECT_FORM_VIEW_TYPE,
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return AndroidViewSurface(
          controller: controller,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        var platformView = PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: COLLECT_FORM_VIEW_TYPE,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: StandardMessageCodec(),
        );
        platformView.addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
        platformView.addOnPlatformViewCreatedListener(_createCardCollectController);
        platformView.create();
        return platformView;
      },
    );
  }

  Widget _collectButton() {
    return MaterialButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      color: Color(0xff3c4c5d),
      child: new Text('Submit', style: new TextStyle(fontSize: 16.0, color: Colors.white)),
      onPressed: () {
        collectController.redactCardAsync().then((value) {
          final entries = value.entries;
          print("value.entries: $entries");

          final errorCode = value[COLLECT_ERROR_CODE_KEY];
          if (errorCode != null) {
            print("error!");
            print("VGS Collect SDK error code: $errorCode");

            final errorMessage = value[COLLECT_ERROR_MESSAGE_KEY];
            if (errorMessage != null) {
              print("VGS Collect SDK error message: $errorMessage");
            }
            return;
          }

          cardToken = value.entries.firstWhere((element) => element.key == CARD_TOKEN_KEY).value;
          dateToken = value.entries.firstWhere((element) => element.key == DATE_TOKEN_KEY).value;

          print("cardToken from collect: $cardToken");
          print("dateToken from collect: $dateToken");
        });
      },
    );
  }

  void _createCardCollectController(int id) {
    print("View id = $id");
    collectController = new CardCollectFormController._(id);
  }

  Widget _cardCollectNativeiOS() {
    final Map<String, dynamic> creationParams = <String, dynamic>{};
    return Column(children: [
      SizedBox(
          height: 136.0,
          child: UiKitView(
              viewType: COLLECT_FORM_VIEW_TYPE,
              onPlatformViewCreated: _createCardCollectController,
              creationParams: creationParams,
              creationParamsCodec: StandardMessageCodec()))
    ]);
  }
}

class CardCollectFormController {
  CardCollectFormController._(int id) : _channel = new MethodChannel('$COLLECT_FORM_VIEW_TYPE/$id');

  final MethodChannel _channel;

  Future<Map<dynamic, dynamic>> redactCardAsync() async {
    return await _channel.invokeMethod('redactCard', null);
  }
}
