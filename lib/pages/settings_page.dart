import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {

    final settings = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // REST TIME
          ListTile(
            title: const Text("Rest Between Sets"),
            subtitle: Text("${settings.restSeconds} seconds"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {

              final value = await _numberPicker(
                context,
                "Rest Between Sets",
                settings.restSeconds,
                10,
                300,
              );

              if (value != null) {
                settings.setRest(value);
              }
            },
          ),

          const Divider(),

          // EXERCISE REST
          ListTile(
            title: const Text("Rest Between Exercises"),
            subtitle: Text("${settings.exerciseRestSeconds} seconds"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {

              final value = await _numberPicker(
                context,
                "Rest Between Exercises",
                settings.exerciseRestSeconds,
                10,
                600,
              );

              if (value != null) {
                settings.setExerciseRest(value);
              }
            },
          ),

          const Divider(),

          // WEIGHT UNIT
          ListTile(
            title: const Text("Weight Unit"),
            subtitle: Text(settings.weightUnit),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {

              final value = await showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text("Weight Unit"),
                  children: [
                    SimpleDialogOption(
                      child: const Text("KG"),
                      onPressed: () => Navigator.pop(context, "KG"),
                    ),
                    SimpleDialogOption(
                      child: const Text("LB"),
                      onPressed: () => Navigator.pop(context, "LB"),
                    ),
                  ],
                ),
              );

              if (value != null) {
                settings.setUnit(value);
              }
            },
          ),

          const Divider(),

          // DARK MODE
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: settings.darkMode,
            onChanged: (v) {
              settings.setTheme(v);
            },
          ),

          const Divider(),

          // 🔊 REST SOUND ENABLE
          SwitchListTile(
            title: const Text("Rest Sound"),
            value: settings.restSoundEnabled,
            onChanged: (v) {
              settings.setRestSoundEnabled(v);
            },
          ),

          const Divider(),

          // 🔊 SOUND TYPE
          ListTile(
            title: const Text("Rest Sound Type"),
            subtitle: Text(settings.restSoundType),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {

              final value = await showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text("Rest Sound Type"),
                  children: [
                    SimpleDialogOption(
                      child: const Text("Air Horn"),
                      onPressed: () => Navigator.pop(context, "airHorn"),
                    ),
                    SimpleDialogOption(
                      child: const Text("Beep"),
                      onPressed: () => Navigator.pop(context, "beep"),
                    ),
                    SimpleDialogOption(
                      child: const Text("Bell"),
                      onPressed: () => Navigator.pop(context, "bell"),
                    ),
                  ],
                ),
              );

              if (value != null) {
                settings.setRestSoundType(value);
              }
            },
          ),

          const Divider(),

          // 🆕 WEEKLY GOAL
          ListTile(
            title: const Text("Weekly Workout Goal"),
            subtitle: Text("${settings.weeklyGoal} workouts per week"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {

              final value = await _numberPicker(
                context,
                "Weekly Goal",
                settings.weeklyGoal,
                1,
                7,
              );

              if (value != null) {
                settings.setWeeklyGoal(value);
              }
            },
          ),

        ],
      ),
    );
  }

  Future<int?> _numberPicker(
      BuildContext context,
      String title,
      int initial,
      int min,
      int max,
      ) async {

    int value = initial;

    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setState) {

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Slider(
                  value: value.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  label: value.toString(),
                  onChanged: (v) {
                    setState(() {
                      value = v.toInt();
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () => Navigator.pop(context, value),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}