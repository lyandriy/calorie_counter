import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await diary.load();
  await goalsStore.load();
  runApp(const CalorieApp());
}

// La raíz de la app: define el tema (colores, estilo) y la primera pantalla.
class CalorieApp extends StatelessWidget {
  const CalorieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Counter',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        // A partir de UN color, Flutter genera toda la paleta.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E9E6B)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi diario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GoalsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          DaySelector(),
          SizedBox(height: 8),
          CaloriesSummaryCard(),
          SizedBox(height: 16),
          MacrosCard(),
          SizedBox(height: 16),
          MealsCard(),
        ],
      ),
    );
  }
}

class CaloriesSummaryCard extends StatelessWidget {
  const CaloriesSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([diary, goalsStore]),
      builder: (context, _) {
        final int goal = goalsStore.goals.calories;
        final int consumed = diary.totalCalories;
        final int remaining = goal - consumed;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: (consumed / goal).clamp(0.0, 1.0).toDouble(),
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          backgroundColor: colors.primaryContainer,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$remaining',
                            style: textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text('kcal restantes', style: textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Objetivo', style: textTheme.bodySmall),
                    Text('$goal kcal', style: textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Text('Consumido', style: textTheme.bodySmall),
                    Text('$consumed kcal', style: textTheme.titleMedium),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MacrosCard extends StatelessWidget {
  const MacrosCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([diary, goalsStore]),
      builder: (context, _) {
        final goals = goalsStore.goals;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                MacroBar(
                  label: 'Proteínas',
                  consumed: diary.totalProtein.round(),
                  goal: goals.protein,
                  color: const Color(0xFFE5574F),
                ),
                const SizedBox(height: 16),
                MacroBar(
                  label: 'Hidratos',
                  consumed: diary.totalCarbs.round(),
                  goal: goals.carbs,
                  color: const Color(0xFFF2A93B),
                ),
                const SizedBox(height: 16),
                MacroBar(
                  label: 'Grasas',
                  consumed: diary.totalFat.round(),
                  goal: goals.fat,
                  color: const Color(0xFF4F8FE5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
// Una barra de macro individual. La escribimos UNA vez y la usamos 3 veces.
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
  });

  final String label;
  final int consumed;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: textTheme.titleSmall),
            Text('$consumed / $goal g', style: textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: consumed / goal,
            minHeight: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

// Iconos disponibles para las comidas. Guardamos la CLAVE (texto), no el icono.
const Map<String, IconData> mealIcons = {
  'restaurant': Icons.restaurant_outlined,
  'breakfast': Icons.free_breakfast_outlined,
  'lunch': Icons.lunch_dining_outlined,
  'dinner': Icons.dinner_dining_outlined,
  'snack': Icons.cookie_outlined,
  'coffee': Icons.local_cafe_outlined,
  'bakery': Icons.bakery_dining_outlined,
  'ramen': Icons.ramen_dining_outlined,
  'fitness': Icons.fitness_center_outlined,
};

class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.goalCalories,
    required this.goalProtein,
    required this.goalCarbs,
    required this.goalFat,
  });

  final String id; // identificador único: no cambia aunque cambie el nombre
  final String name;
  final String iconKey;
  final int goalCalories;
  final int goalProtein; // gramos
  final int goalCarbs;
  final int goalFat;

  IconData get icon => mealIcons[iconKey] ?? Icons.restaurant_outlined;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'goalCalories': goalCalories,
        'goalProtein': goalProtein,
        'goalCarbs': goalCarbs,
        'goalFat': goalFat,
      };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id'] as String,
        name: json['name'] as String,
        iconKey: json['iconKey'] as String,
        goalCalories: json['goalCalories'] as int,
        goalProtein: json['goalProtein'] as int,
        goalCarbs: json['goalCarbs'] as int,
        goalFat: json['goalFat'] as int,
      );
}

// Las comidas iniciales. Sus ids son los nombres de antes, para que los
// alimentos que ya habías añadido sigan apareciendo en su comida.
const List<Meal> defaultMeals = [
  Meal(id: 'Desayuno', name: 'Desayuno', iconKey: 'breakfast', goalCalories: 500, goalProtein: 35, goalCarbs: 55, goalFat: 16),
  Meal(id: 'Comida', name: 'Comida', iconKey: 'lunch', goalCalories: 800, goalProtein: 56, goalCarbs: 88, goalFat: 26),
  Meal(id: 'Merienda', name: 'Merienda', iconKey: 'snack', goalCalories: 200, goalProtein: 14, goalCarbs: 22, goalFat: 7),
  Meal(id: 'Cena', name: 'Cena', iconKey: 'dinner', goalCalories: 500, goalProtein: 35, goalCarbs: 55, goalFat: 16),
];

class MealsStore extends ChangeNotifier {
  static const String _storageKey = 'meals';

  List<Meal> _meals = List.of(defaultMeals);
  List<Meal> get meals => List.unmodifiable(_meals);

  void add(Meal meal) {
    _meals.add(meal);
    _changed();
  }

  void update(Meal meal) {
    final index = _meals.indexWhere((m) => m.id == meal.id);
    if (index == -1) return;
    _meals[index] = meal;
    _changed();
  }

  void remove(String id) {
    _meals.removeWhere((m) => m.id == id);
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_storageKey);
    if (text == null) return; // primera vez: nos quedamos con las iniciales
    final list = jsonDecode(text) as List<dynamic>;
    _meals = list.map((m) => Meal.fromJson(m as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_meals.map((m) => m.toJson()).toList()),
    );
  }
}

final mealsStore = MealsStore();

class MealsCard extends StatelessWidget {
  const MealsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([diary, mealsStore]),
      builder: (context, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Comidas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Gestionar comidas',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageMealsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                for (final meal in mealsStore.meals) MealTile(meal: meal),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MealTile extends StatelessWidget {
  const MealTile({super.key, required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final int consumed = diary.caloriesFor(meal);
    final bool overGoal = consumed > meal.goalCalories;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        child: Icon(meal.icon, color: colors.onPrimaryContainer),
      ),
      title: Text(meal.name),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MealDetailScreen(meal: meal)),
        );
      },
      subtitle: Text(
        '$consumed / ${meal.goalCalories} kcal',
        style: TextStyle(color: overGoal ? colors.error : null),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddFoodScreen(meal: meal)),
          );
        },
      ),
    );
  }
}

// Valores nutricionales por cada 100 g: calorías, proteínas, hidratos, grasas.
class Nutrition {
  const Nutrition(this.calories, this.protein, this.carbs, this.fat);

  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory Nutrition.fromJson(Map<String, dynamic> json) => Nutrition(
        json['calories'] as int,
        (json['protein'] as num).toDouble(),
        (json['carbs'] as num).toDouble(),
        (json['fat'] as num).toDouble(),
      );
}

// Una unidad de medida y a cuántos gramos equivale.
class FoodUnit {
  const FoodUnit(this.label, this.gramsPerUnit, {this.defaultAmount = 1});

  final String label;
  final double gramsPerUnit;
  final double defaultAmount; // cantidad que se propone al elegirla

  static const grams = FoodUnit('g', 1, defaultAmount: 100);

  Map<String, dynamic> toJson() => {
        'label': label,
        'gramsPerUnit': gramsPerUnit,
        'defaultAmount': defaultAmount,
      };

  factory FoodUnit.fromJson(Map<String, dynamic> json) => FoodUnit(
        json['label'] as String,
        (json['gramsPerUnit'] as num).toDouble(),
        defaultAmount: (json['defaultAmount'] as num).toDouble(),
      );
}

class Food {
  const Food({
    required this.name,
    required this.states,
    this.units = const [FoodUnit.grams],
  });

  final String name;
  // Estado del alimento -> valores por 100 g. El primero es el predeterminado.
  final Map<String, Nutrition> states;
  final List<FoodUnit> units;

  String get defaultState => states.keys.first;
  Nutrition get defaultNutrition => states.values.first;

  Map<String, dynamic> toJson() => {
        'name': name,
        'states': states.map((key, value) => MapEntry(key, value.toJson())),
        'units': units.map((u) => u.toJson()).toList(),
      };

  factory Food.fromJson(Map<String, dynamic> json) => Food(
        name: json['name'] as String,
        states: (json['states'] as Map<String, dynamic>).map(
          (key, value) =>
              MapEntry(key, Nutrition.fromJson(value as Map<String, dynamic>)),
        ),
        units: (json['units'] as List<dynamic>)
            .map((u) => FoodUnit.fromJson(u as Map<String, dynamic>))
            .toList(),
      );
}

// Datos de prueba APROXIMADOS. Más adelante usaremos una fuente oficial.
const List<Food> sampleFoods = [
  Food(
    name: 'Manzana',
    states: {'Natural': Nutrition(52, 0.3, 14, 0.2)},
    units: [FoodUnit.grams, FoodUnit('ud.', 180)],
  ),
  Food(
    name: 'Plátano',
    states: {'Natural': Nutrition(89, 1.1, 23, 0.3)},
    units: [FoodUnit.grams, FoodUnit('ud.', 120)],
  ),
  Food(
    name: 'Huevo',
    states: {
      'Crudo': Nutrition(143, 12.6, 0.7, 9.5),
      'Cocido': Nutrition(155, 12.6, 1.1, 10.6),
      'Frito': Nutrition(196, 13.6, 0.8, 14.8),
    },
    units: [FoodUnit.grams, FoodUnit('ud.', 55)],
  ),
  Food(
    name: 'Pechuga de pollo',
    states: {
      'Cruda': Nutrition(120, 22.5, 0, 2.6),
      'A la plancha': Nutrition(165, 31, 0, 3.6),
    },
  ),
  Food(
    name: 'Salmón',
    states: {
      'Crudo': Nutrition(208, 20, 0, 13),
      'Al horno': Nutrition(206, 22.1, 0, 12.4),
    },
  ),
  Food(
    name: 'Arroz blanco',
    states: {
      'Crudo': Nutrition(360, 7, 79, 0.6),
      'Cocido': Nutrition(130, 2.7, 28, 0.3),
    },
  ),
  Food(
    name: 'Brócoli',
    states: {
      'Crudo': Nutrition(34, 2.8, 7, 0.4),
      'Cocido': Nutrition(35, 2.4, 7.2, 0.4),
    },
  ),
  Food(
    name: 'Leche entera',
    states: {'Natural': Nutrition(61, 3.2, 4.8, 3.3)},
    units: [FoodUnit.grams, FoodUnit('ml', 1.03, defaultAmount: 200)],
  ),
  Food(
    name: 'Aceite de oliva',
    states: {'Natural': Nutrition(884, 0, 0, 100)},
    units: [
      FoodUnit.grams,
      FoodUnit('ml', 0.91, defaultAmount: 15),
      FoodUnit('cda.', 13.5),
    ],
  ),
];

// Muestra 150 en vez de 150.0, pero deja 1.5 como 1.5.
String formatAmount(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toString();

// Lo que devuelve el panel de cantidad: estado, unidad y cantidad elegidos.
typedef Selection = ({String state, FoodUnit unit, double amount});

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key, required this.meal});

  final Meal meal;

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

// Aquí vive el estado: los datos que pueden cambiar.
class _AddFoodScreenState extends State<AddFoodScreen> {
  String query = ''; // lo que el usuario ha escrito

  @override
  Widget build(BuildContext context) {
    // Nos quedamos solo con los alimentos cuyo nombre contiene el texto.
    final results = sampleFoods
        .where((food) => food.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Añadir a ${widget.meal.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Buscar alimento',
              leading: const Icon(Icons.search),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('No se han encontrado alimentos'))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final food = results[index];
                      return ListTile(
                        title: Text(food.name),
                        subtitle: Text('${food.defaultNutrition.calories} kcal · 100 g'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final selection = await showModalBottomSheet<Selection>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (context) => QuantitySheet(food: food),
                          );
                          if (selection != null && context.mounted) {
                            diary.add(
                              DiaryEntry(
                                food: food,
                                state: selection.state,
                                unit: selection.unit,
                                amount: selection.amount,
                                mealId: widget.meal.id,
                                date: diary.selectedDate,
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${food.name}: ${formatAmount(selection.amount)} '
                                  '${selection.unit.label} en ${widget.meal.name}',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class QuantitySheet extends StatefulWidget {
  const QuantitySheet({super.key, required this.food, this.entry});

  final Food food;
  final DiaryEntry? entry;

  @override
  State<QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<QuantitySheet> {
  late String state;
  late FoodUnit unit;
  late double amount;
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    state = entry?.state ?? widget.food.defaultState;
    unit = entry?.unit ?? widget.food.units.first;
    amount = entry?.amount ?? unit.defaultAmount;
    controller = TextEditingController(text: formatAmount(amount));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _selectUnit(FoodUnit newUnit) {
    setState(() {
      unit = newUnit;
      amount = newUnit.defaultAmount;
      controller.text = formatAmount(amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final textTheme = Theme.of(context).textTheme;

    // Reutilizamos DiaryEntry solo para calcular la vista previa.
    final preview = DiaryEntry(
      food: food,
      state: state,
      unit: unit,
      amount: amount,
      mealId: '',
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(food.name, style: textTheme.titleLarge),
            const SizedBox(height: 16),
            // Solo mostramos los estados si hay más de uno.
            if (food.states.length > 1) ...[
              Wrap(
                spacing: 8,
                children: [
                  for (final s in food.states.keys)
                    ChoiceChip(
                      label: Text(s),
                      selected: s == state,
                      onSelected: (_) => setState(() => state = s),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Cantidad',
                suffixText: unit.label,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  // Aceptamos coma o punto como separador decimal.
                  amount = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                });
              },
            ),
            if (food.units.length > 1) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final u in food.units)
                    ChoiceChip(
                      label: Text(u.label),
                      selected: u.label == unit.label,
                      onSelected: (_) => _selectUnit(u),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '${preview.calories} kcal',
              style: textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'P ${preview.protein.toStringAsFixed(1)} g  ·  '
              'H ${preview.carbs.toStringAsFixed(1)} g  ·  '
              'G ${preview.fat.toStringAsFixed(1)} g',
              style: textTheme.bodyMedium,
            ),
            if (unit.label != 'g')
              Text(
                '≈ ${preview.grams.round()} g',
                style: textTheme.bodySmall,
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: amount > 0
                    ? () => Navigator.pop(
                          context,
                          (state: state, unit: unit, amount: amount),
                        )
                    : null,
                  child: Text(widget.entry == null ? 'Añadir' : 'Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiaryEntry {
  DiaryEntry({
    required this.food,
    required this.state,
    required this.unit,
    required this.amount,
    required this.mealId,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  final Food food;
  final String state;
  final FoodUnit unit;
  final double amount;
  final String mealId;
  final DateTime date;

  double get grams => amount * unit.gramsPerUnit;
  Nutrition get _nutrition => food.states[state]!;

  int get calories => (_nutrition.calories * grams / 100).round();
  double get protein => _nutrition.protein * grams / 100;
  double get carbs => _nutrition.carbs * grams / 100;
  double get fat => _nutrition.fat * grams / 100;

  Map<String, dynamic> toJson() => {
        'food': food.toJson(),
        'state': state,
        'unit': unit.toJson(),
        'amount': amount,
        'mealId': mealId,
        'date': date.toIso8601String(),
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        food: Food.fromJson(json['food'] as Map<String, dynamic>),
        state: json['state'] as String,
        unit: FoodUnit.fromJson(json['unit'] as Map<String, dynamic>),
        amount: (json['amount'] as num).toDouble(),
        // Los datos antiguos guardaban 'mealName': los seguimos entendiendo.
        mealId: (json['mealId'] ?? json['mealName']) as String,
        date: DateTime.parse(json['date'] as String),
      );
}

class Diary extends ChangeNotifier {
  static const String _storageKey = 'diary_entries_v2';

  final List<DiaryEntry> _entries = [];

  // El día que se está mostrando (empieza siendo hoy).
  DateTime _selectedDate = dateOnly(DateTime.now());
  DateTime get selectedDate => _selectedDate;

  void selectDate(DateTime date) {
    _selectedDate = dateOnly(date);
    notifyListeners();
  }

  void changeDay(int days) => selectDate(addDays(_selectedDate, days));

  // Solo las entradas del día seleccionado.
  List<DiaryEntry> get _dayEntries =>
      _entries.where((e) => dateOnly(e.date) == _selectedDate).toList();

  void add(DiaryEntry entry) {
    _entries.add(entry);
    notifyListeners();
    _save();
  }

  void remove(DiaryEntry entry) {
    _entries.remove(entry);
    notifyListeners();
    _save();
  }

  void replace(DiaryEntry old, DiaryEntry updated) {
    final index = _entries.indexOf(old);
    if (index == -1) return;
    _entries[index] = updated;
    notifyListeners();
    _save();
  }

  List<DiaryEntry> entriesFor(Meal meal) =>
      _dayEntries.where((e) => e.mealId == meal.id).toList();

  // Borra los alimentos de una comida en TODOS los días.
  void removeEntriesOfMeal(String mealId) {
    _entries.removeWhere((e) => e.mealId == mealId);
    notifyListeners();
    _save();
  }

  int get totalCalories => _dayEntries.fold(0, (sum, e) => sum + e.calories);
  double get totalProtein => _dayEntries.fold(0.0, (sum, e) => sum + e.protein);
  double get totalCarbs => _dayEntries.fold(0.0, (sum, e) => sum + e.carbs);
  double get totalFat => _dayEntries.fold(0.0, (sum, e) => sum + e.fat);

  int caloriesFor(Meal meal) =>
      entriesFor(meal).fold(0, (sum, e) => sum + e.calories);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_storageKey);
    if (text == null) return;

    final list = jsonDecode(text) as List<dynamic>;
    _entries
      ..clear()
      ..addAll(
        list.map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>)),
      );
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final text = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, text);
  }
}

// Una única instancia, accesible desde cualquier pantalla.
final diary = Diary();

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key, required this.meal});

  final Meal meal;

  void _delete(BuildContext context, DiaryEntry entry) {
    diary.remove(entry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${entry.food.name} eliminado'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => diary.add(entry),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(meal.name)),
      body: ListenableBuilder(
        listenable: diary,
        builder: (context, _) {
          final entries = diary.entriesFor(meal);
          final protein = entries.fold(0.0, (sum, e) => sum + e.protein);
          final carbs = entries.fold(0.0, (sum, e) => sum + e.carbs);
          final fat = entries.fold(0.0, (sum, e) => sum + e.fat);

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      MacroBar(
                        label: 'Proteínas',
                        consumed: protein.round(),
                        goal: meal.goalProtein,
                        color: const Color(0xFFE5574F),
                      ),
                      const SizedBox(height: 12),
                      MacroBar(
                        label: 'Hidratos',
                        consumed: carbs.round(),
                        goal: meal.goalCarbs,
                        color: const Color(0xFFF2A93B),
                      ),
                      const SizedBox(height: 12),
                      MacroBar(
                        label: 'Grasas',
                        consumed: fat.round(),
                        goal: meal.goalFat,
                        color: const Color(0xFF4F8FE5),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('Todavía no has añadido nada'))
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final stateText = entry.food.states.length > 1
                              ? ' · ${entry.state}'
                              : '';

                          return Dismissible(
                            key: ObjectKey(entry),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Theme.of(context).colorScheme.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _delete(context, entry),
                            child: ListTile(
                              title: Text(entry.food.name),
                              subtitle: Text(
                                '${formatAmount(entry.amount)} ${entry.unit.label}$stateText'
                                ' · ${entry.calories} kcal',
                              ),
                              onTap: () async {
                                final selection =
                                    await showModalBottomSheet<Selection>(
                                  context: context,
                                  isScrollControlled: true,
                                  showDragHandle: true,
                                  builder: (context) => QuantitySheet(
                                    food: entry.food,
                                    entry: entry,
                                  ),
                                );
                                if (selection != null) {
                                  diary.replace(
                                    entry,
                                    DiaryEntry(
                                      food: entry.food,
                                      state: selection.state,
                                      unit: selection.unit,
                                      amount: selection.amount,
                                      mealId: entry.mealId,
                                      date: entry.date,
                                    ),
                                  );
                                }
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(context, entry),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class Goals {
  const Goals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int calories; // kcal al día
  final int protein; // gramos al día
  final int carbs;
  final int fat;

  // Valores iniciales, hasta que el usuario los cambie.
  static const defaults = Goals(calories: 2000, protein: 140, carbs: 220, fat: 65);

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory Goals.fromJson(Map<String, dynamic> json) => Goals(
        calories: json['calories'] as int,
        protein: json['protein'] as int,
        carbs: json['carbs'] as int,
        fat: json['fat'] as int,
      );
}

class GoalsStore extends ChangeNotifier {
  static const String _storageKey = 'goals';

  Goals _goals = Goals.defaults;
  Goals get goals => _goals;

  void update(Goals newGoals) {
    _goals = newGoals;
    notifyListeners();
    _save();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_storageKey);
    if (text == null) return; // primera vez: nos quedamos con los valores iniciales
    _goals = Goals.fromJson(jsonDecode(text) as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_goals.toJson()));
  }
}

final goalsStore = GoalsStore();

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late final TextEditingController calories;
  late final TextEditingController protein;
  late final TextEditingController carbs;
  late final TextEditingController fat;

  @override
  void initState() {
    super.initState();
    final g = goalsStore.goals;
    calories = TextEditingController(text: '${g.calories}');
    protein = TextEditingController(text: '${g.protein}');
    carbs = TextEditingController(text: '${g.carbs}');
    fat = TextEditingController(text: '${g.fat}');
  }

  @override
  void dispose() {
    calories.dispose();
    protein.dispose();
    carbs.dispose();
    fat.dispose();
    super.dispose();
  }

  // Lee un campo como número (0 si está vacío o no es válido).
  int _value(TextEditingController c) => int.tryParse(c.text) ?? 0;

  // Todos tienen que ser mayores que 0 (con 0 las barras darían error).
  bool get _isValid =>
      _value(calories) > 0 &&
      _value(protein) > 0 &&
      _value(carbs) > 0 &&
      _value(fat) > 0;

  Widget _field(String label, String suffix, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}), // recalcular el aviso y el botón
      ),
    );
  }

  void _save() {
    goalsStore.update(
      Goals(
        calories: _value(calories),
        protein: _value(protein),
        carbs: _value(carbs),
        fat: _value(fat),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // 1 g de proteína o hidratos = 4 kcal; 1 g de grasa = 9 kcal.
    final macroKcal =
        _value(protein) * 4 + _value(carbs) * 4 + _value(fat) * 9;
    final diff = macroKcal - _value(calories);
    final diffText = diff > 0 ? '+$diff' : '$diff';

    return Scaffold(
      appBar: AppBar(title: const Text('Objetivos diarios')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('Calorías', 'kcal', calories),
          _field('Proteínas', 'g', protein),
          _field('Hidratos', 'g', carbs),
          _field('Grasas', 'g', fat),
          Text(
            'Tus macros suman $macroKcal kcal ($diffText respecto a tu objetivo de calorías).',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isValid ? _save : null,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

// Una fecha sin la hora: 11 nov 2026 a las 00:00.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// Suma (o resta) días a una fecha.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

class DaySelector extends StatelessWidget {
  const DaySelector({super.key});

  String _label(BuildContext context) {
    final selected = diary.selectedDate;
    final today = dateOnly(DateTime.now());

    if (selected == today) return 'Hoy';
    if (selected == addDays(today, -1)) return 'Ayer';
    if (selected == addDays(today, 1)) return 'Mañana';
    return MaterialLocalizations.of(context).formatMediumDate(selected);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: diary,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => diary.changeDay(-1),
            ),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: diary.selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) diary.selectDate(picked);
              },
              child: Text(
                _label(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => diary.changeDay(1),
            ),
          ],
        );
      },
    );
  }
}

// Lista de comidas con botón para crear una nueva.
class ManageMealsScreen extends StatelessWidget {
  const ManageMealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis comidas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MealEditScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Añadir comida'),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([mealsStore, goalsStore]),
        builder: (context, _) {
          final meals = mealsStore.meals;
          final total = meals.fold(0, (sum, m) => sum + m.goalCalories);
          final daily = goalsStore.goals.calories;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Text(
                meals.isEmpty
                    ? 'No tienes ninguna comida. ¡Añade la primera!'
                    : 'Tus comidas suman $total kcal (objetivo diario: $daily kcal).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final meal in meals)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(meal.icon, color: colors.onPrimaryContainer),
                  ),
                  title: Text(meal.name),
                  subtitle: Text(
                    '${meal.goalCalories} kcal · P ${meal.goalProtein} g · '
                    'H ${meal.goalCarbs} g · G ${meal.goalFat} g',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MealEditScreen(meal: meal),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

// Crear o editar una comida.
class MealEditScreen extends StatefulWidget {
  const MealEditScreen({super.key, this.meal});

  final Meal? meal; // null = crear una comida nueva

  @override
  State<MealEditScreen> createState() => _MealEditScreenState();
}

class _MealEditScreenState extends State<MealEditScreen> {
  late final TextEditingController name;
  late final TextEditingController calories;
  late final TextEditingController protein;
  late final TextEditingController carbs;
  late final TextEditingController fat;
  late String iconKey;

  @override
  void initState() {
    super.initState();
    final m = widget.meal;
    name = TextEditingController(text: m?.name ?? '');
    calories = TextEditingController(text: '${m?.goalCalories ?? 500}');
    protein = TextEditingController(text: '${m?.goalProtein ?? 35}');
    carbs = TextEditingController(text: '${m?.goalCarbs ?? 55}');
    fat = TextEditingController(text: '${m?.goalFat ?? 16}');
    iconKey = m?.iconKey ?? 'restaurant';
  }

  @override
  void dispose() {
    name.dispose();
    calories.dispose();
    protein.dispose();
    carbs.dispose();
    fat.dispose();
    super.dispose();
  }

  int _value(TextEditingController c) => int.tryParse(c.text) ?? 0;

  bool get _isValid =>
      name.text.trim().isNotEmpty &&
      _value(calories) > 0 &&
      _value(protein) > 0 &&
      _value(carbs) > 0 &&
      _value(fat) > 0;

  Widget _field(String label, String suffix, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  void _save() {
    final old = widget.meal;
    final meal = Meal(
      // Una comida nueva recibe un id único a partir de la hora actual.
      id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.text.trim(),
      iconKey: iconKey,
      goalCalories: _value(calories),
      goalProtein: _value(protein),
      goalCarbs: _value(carbs),
      goalFat: _value(fat),
    );

    if (old == null) {
      mealsStore.add(meal);
    } else {
      mealsStore.update(meal);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final meal = widget.meal!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar comida?'),
        content: Text(
          'Se eliminarán también todos los alimentos registrados en '
          '"${meal.name}", de todos los días.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      diary.removeEntriesOfMeal(meal.id);
      mealsStore.remove(meal.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.meal != null;

    final macroKcal =
        _value(protein) * 4 + _value(carbs) * 4 + _value(fat) * 9;
    final diff = macroKcal - _value(calories);
    final diffText = diff > 0 ? '+$diff' : '$diff';

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar comida' : 'Nueva comida')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              controller: name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Text('Icono', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in mealIcons.entries)
                ChoiceChip(
                  label: Icon(entry.value),
                  showCheckmark: false,
                  selected: entry.key == iconKey,
                  onSelected: (_) => setState(() => iconKey = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _field('Calorías', 'kcal', calories),
          _field('Proteínas', 'g', protein),
          _field('Hidratos', 'g', carbs),
          _field('Grasas', 'g', fat),
          Text(
            'Tus macros suman $macroKcal kcal ($diffText respecto al objetivo de esta comida).',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isValid ? _save : null,
            child: const Text('Guardar'),
          ),
          if (isEditing) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _delete,
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                'Eliminar comida',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}