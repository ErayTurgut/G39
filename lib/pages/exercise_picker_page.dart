import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExercisePickerPage extends StatefulWidget {
  const ExercisePickerPage({super.key});

  @override
  State<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<ExercisePickerPage> {
  String search = "";
  String selectedCategory = "All";

  List<String> favorites = [];
  List<String> recents = [];

  // 🔥 GÜNCELLENMİŞ VE PROFESYONEL HAREKET LİSTESİ
  final List<Map<String, String>> exercises = [
    /// ================= CHEST (GÖĞÜS) =================
    {"name": "Barbell Bench Press", "region": "Chest", "type": "Free"},
    {"name": "Dumbbell Bench Press", "region": "Chest", "type": "Free"},
    {"name": "Machine Bench Press", "region": "Chest", "type": "Machine"},
    {"name": "Barbell Incline Bench Press", "region": "Chest", "type": "Free"},
    {"name": "Dumbbell Incline Bench Press", "region": "Chest", "type": "Free"},
    {"name": "Machine Incline Press", "region": "Chest", "type": "Machine"},
    {"name": "Smith Machine Incline Press", "region": "Chest", "type": "Machine"},
    {"name": "Barbell Decline Bench Press", "region": "Chest", "type": "Free"},
    {"name": "Dumbbell Decline Bench Press", "region": "Chest", "type": "Free"},
    {"name": "Chest Fly", "region": "Chest", "type": "Machine"},
    {"name": "Dumbbell Fly", "region": "Chest", "type": "Free"},
    {"name": "Cable Fly", "region": "Chest", "type": "Cable"},
    {"name": "Cable Crossover", "region": "Chest", "type": "Cable"},
    {"name": "Pec Deck", "region": "Chest", "type": "Machine"},
    {"name": "Push Up", "region": "Chest", "type": "Bodyweight"},
    {"name": "Incline Push Up", "region": "Chest", "type": "Bodyweight"},
    {"name": "Decline Push Up", "region": "Chest", "type": "Bodyweight"},

    /// ================= BACK (SIRT) =================
    {"name": "Deadlift", "region": "Back", "type": "Free"},
    {"name": "Barbell Row", "region": "Back", "type": "Free"},
    {"name": "Dumbbell Row", "region": "Back", "type": "Free"},
    {"name": "Meadows Row", "region": "Back", "type": "Free"},
    {"name": "T-Bar Row", "region": "Back", "type": "Free"},
    {"name": "Seated Row", "region": "Back", "type": "Machine"},
    {"name": "Lat Pulldown", "region": "Back", "type": "Machine"},
    {"name": "Wide Grip Pulldown", "region": "Back", "type": "Machine"},
    {"name": "Close Grip Pulldown", "region": "Back", "type": "Machine"},
    {"name": "Rope Pulldown", "region": "Back", "type": "Cable"},
    {"name": "Straight Arm Pulldown", "region": "Back", "type": "Cable"},
    {"name": "Single Arm Lat Pulldown", "region": "Back", "type": "Cable"},
    {"name": "Cable Row", "region": "Back", "type": "Cable"},
    {"name": "Pull Up", "region": "Back", "type": "Bodyweight"},
    {"name": "Chin Up", "region": "Back", "type": "Bodyweight"},
    {"name": "Hyperextension", "region": "Back", "type": "Bodyweight"},

    /// ================= LEG (BACAK) =================
    {"name": "Barbell Squat", "region": "Leg", "type": "Free"},
    {"name": "Dumbbell Squat", "region": "Leg", "type": "Free"},
    {"name": "Goblet Squat (Dumbbell)", "region": "Leg", "type": "Free"},
    {"name": "Smith Machine Squat", "region": "Leg", "type": "Machine"},
    {"name": "Front Squat", "region": "Leg", "type": "Free"},
    {"name": "Hack Squat", "region": "Leg", "type": "Machine"},
    {"name": "Leg Press", "region": "Leg", "type": "Machine"},
    {"name": "Leg Extension", "region": "Leg", "type": "Machine"},
    {"name": "Leg Curl", "region": "Leg", "type": "Machine"},
    {"name": "Romanian Deadlift", "region": "Leg", "type": "Free"},
    {"name": "Stiff Leg Deadlift", "region": "Leg", "type": "Free"},
    {"name": "Hip Thrust", "region": "Leg", "type": "Free"},
    {"name": "Glute Bridge", "region": "Leg", "type": "Bodyweight"},
    {"name": "Lunge", "region": "Leg", "type": "Free"},
    {"name": "Walking Lunge", "region": "Leg", "type": "Free"},
    {"name": "Bulgarian Split Squat", "region": "Leg", "type": "Free"},
    {"name": "Calf Raise", "region": "Leg", "type": "Machine"},
    {"name": "Seated Calf Raise", "region": "Leg", "type": "Machine"},

    /// ================= SHOULDER (OMUZ) =================
    {"name": "Barbell Shoulder Press", "region": "Shoulder", "type": "Free"},
    {"name": "Dumbbell Shoulder Press", "region": "Shoulder", "type": "Free"},
    {"name": "Arnold Press", "region": "Shoulder", "type": "Free"},
    {"name": "Machine Shoulder Press", "region": "Shoulder", "type": "Machine"},
    {"name": "Smith Machine Shoulder Press", "region": "Shoulder", "type": "Machine"},
    {"name": "Lateral Raise", "region": "Shoulder", "type": "Free"},
    {"name": "Single Arm Cable Lateral Raise", "region": "Shoulder", "type": "Cable"},
    {"name": "Front Raise", "region": "Shoulder", "type": "Free"},
    {"name": "Rear Delt Fly", "region": "Shoulder", "type": "Machine"},
    {"name": "Face Pull", "region": "Shoulder", "type": "Cable"},
    {"name": "Upright Row", "region": "Shoulder", "type": "Free"},
    {"name": "Shrug", "region": "Shoulder", "type": "Free"},

    /// ================= ARM (KOL) =================
    {"name": "Barbell Curl", "region": "Arm", "type": "Free"},
    {"name": "Dumbbell Curl", "region": "Arm", "type": "Free"},
    {"name": "EZ-Bar Curl", "region": "Arm", "type": "Free"},
    {"name": "Hammer Curl", "region": "Arm", "type": "Free"},
    {"name": "Rope Hammer Curl", "region": "Arm", "type": "Cable"},
    {"name": "Cable Curl", "region": "Arm", "type": "Cable"},
    {"name": "Concentration Curl", "region": "Arm", "type": "Free"},
    {"name": "Preacher Curl", "region": "Arm", "type": "Machine"},
    {"name": "Triceps Pushdown", "region": "Arm", "type": "Cable"},
    {"name": "Rope Pushdown", "region": "Arm", "type": "Cable"},
    {"name": "Overhead Triceps Extension", "region": "Arm", "type": "Free"},
    {"name": "Skull Crusher", "region": "Arm", "type": "Free"},
    {"name": "Dips", "region": "Arm", "type": "Bodyweight"},
    {"name": "Close Grip Bench Press", "region": "Arm", "type": "Free"},

    /// ================= CORE (KARIN) =================
    {"name": "Crunch", "region": "Core", "type": "Bodyweight"},
    {"name": "Sit Up", "region": "Core", "type": "Bodyweight"},
    {"name": "Leg Raise", "region": "Core", "type": "Bodyweight"},
    {"name": "Hanging Leg Raise", "region": "Core", "type": "Bodyweight"},
    {"name": "Cable Crunch", "region": "Core", "type": "Cable"},
    {"name": "Plank", "region": "Core", "type": "Bodyweight"},
    {"name": "Side Plank", "region": "Core", "type": "Bodyweight"},
    {"name": "Russian Twist", "region": "Core", "type": "Bodyweight"},
    {"name": "Mountain Climber", "region": "Core", "type": "Bodyweight"},
  ];

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList("favorites") ?? [];
      recents = prefs.getStringList("recents") ?? [];
    });
  }

  Future<void> savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("favorites", favorites);
    await prefs.setStringList("recents", recents);
  }

  void toggleFavorite(String name) {
    setState(() {
      if (favorites.contains(name)) {
        favorites.remove(name);
      } else {
        favorites.add(name);
      }
    });
    savePrefs();
  }

  void addRecent(String name) {
    recents.remove(name);
    recents.insert(0, name);
    if (recents.length > 10) {
      recents = recents.sublist(0, 10);
    }
    savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = exercises.where((e) {
      final matchesSearch = e["name"]!.toLowerCase().contains(search.toLowerCase());
      final matchesCategory = selectedCategory == "All" || e["region"] == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Hareket Seç")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Hareket ara (Dumbbell, Rope...)",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  search = val;
                });
              },
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip("All"),
                _chip("Chest"),
                _chip("Back"),
                _chip("Leg"),
                _chip("Shoulder"),
                _chip("Arm"),
                _chip("Core"),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final ex = filtered[index];
                final name = ex["name"]!;
                final isFav = favorites.contains(name);

                return ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${ex["region"]} • ${ex["type"]}"),
                  trailing: IconButton(
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav ? Colors.amber : null,
                    ),
                    onPressed: () => toggleFavorite(name),
                  ),
                  onTap: () {
                    addRecent(name);
                    Navigator.pop(context, ex);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    final selected = selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        onSelected: (_) {
          setState(() {
            selectedCategory = label;
          });
        },
      ),
    );
  }
}