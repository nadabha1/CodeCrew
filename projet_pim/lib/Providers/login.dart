import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../ViewModel/login.dart';

class LoginProvider {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (_) => LoginViewModel()),
  ];
}
