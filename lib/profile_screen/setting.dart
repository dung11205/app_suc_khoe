import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettingsProvider>(context);
    final isDark = settings.themeMode == ThemeMode.dark;
    final lang = settings.locale.languageCode;
    final loc = AppLocalizations.of(context)!; 

    return Scaffold(
      appBar: AppBar(title: Text(loc.settings)),
      body: ListView(
        children: [
          ListTile(title: Text(loc.language)), 
  
          RadioListTile<String>(
            title: Text(loc.vietnamese),
            value: 'vi',
            groupValue: lang,
            onChanged: (val) {
              if (val != null) settings.updateLanguage(val);
            },
          ),
          RadioListTile<String>(
            title: Text(loc.english),
            value: 'en',
            groupValue: lang,
            onChanged: (val) {
              if (val != null) settings.updateLanguage(val);
            },
          ),
          const Divider(),

          SwitchListTile(
            title: Text(loc.darkMode),
            value: isDark,
            onChanged: (val) => settings.updateTheme(val),
          ),
        ],
      ),
    );
  }
}
