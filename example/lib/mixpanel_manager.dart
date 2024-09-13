import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class MixpanelManager {
  static Mixpanel? _instance;

  static Future<Mixpanel> init() async {
    _instance ??= await Mixpanel.init('f3132cbb2645d462c7b2058cb6e8e8f6', trackAutomaticEvents: true);
    return _instance!;
  }
}