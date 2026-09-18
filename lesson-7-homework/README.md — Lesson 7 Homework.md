# Домашнє завдання після заняття 7

Домашнє завдання охоплює:

- заняття 6 — FSM;
- заняття 7 — Static Timing Analysis (STA) та Timing Constraints.

Для синтезу та статичного часового аналізу використано **Quartus Prime Lite** та FPGA **Cyclone IV E EP4CE6E22C8**.

Для функціональної симуляції використано **ModelSim**.

---

# Частина 1 — Контролер замка

Реалізовано FSM-контролер електронного замка з кодом:

```text
5 → 3 → 7
```

Контролер має чотири стани:

```text
LOCKED
WAIT_D2
WAIT_D3
UNLOCKED
```

Правильна послідовність переходів:

```text
LOCKED
   |
   | digit = 5
   v
WAIT_D2
   |
   | digit = 3
   v
WAIT_D3
   |
   | digit = 7
   v
UNLOCKED
```

При введенні неправильної цифри контролер повертається до стану `LOCKED`.

У стані `UNLOCKED` контролер залишається розблокованим до отримання сигналу `rst`.

Вихід:

```text
unlocked_led = 1
```

активний тільки у стані `UNLOCKED`.

## Three-process FSM

FSM реалізовано за three-process pattern:

1. процес регістра стану;
2. комбінаційний процес визначення наступного стану;
3. комбінаційний процес формування виходу `unlocked_led`.

Це дозволяє розділити:

```text
State Register
      |
      v
Next-State Logic
      |
      v
Output Logic
```

та зробити структуру FSM зрозумілою і передбачуваною для синтезу.

## Debounce

Для `digit_in`, який може надходити від фізичних кнопок, додано окремий debounce-фільтр.

Debounce містить:

- двоступеневу синхронізацію вхідного сигналу;
- перевірку стабільності значення протягом заданої кількості тактів;
- оновлення вихідного значення тільки після підтвердження його стабільності.

Загальна структура:

```text
Physical buttons
       |
       v
 Synchronizer
       |
       v
 Debounce filter
       |
       v
 debounced_digit
       |
       v
 Lock Controller FSM
```

Це запобігає багаторазовій обробці коротких нестабільних переходів, спричинених механічним брязкотом контактів кнопок.

## Testbench

Testbench перевіряє:

- asynchronous reset;
- правильне введення першої цифри;
- перехід `LOCKED → WAIT_D2`;
- правильне введення другої цифри;
- перехід `WAIT_D2 → WAIT_D3`;
- правильне введення третьої цифри;
- перехід `WAIT_D3 → UNLOCKED`;
- утримання стану `UNLOCKED`;
- неправильну цифру та повернення в `LOCKED`;
- моделювання bounce фізичних кнопок.

---

# Частина 2 — Аналіз Timing Summary Report

Мета цієї частини — виконати Static Timing Analysis та отримати реальне значення Worst-case Setup Slack (WNS).

Для аналізу використано `ExprPlain`.

Входи схеми зареєстровані, тому основні внутрішні часові шляхи мають тип:

```text
register → combinational logic → register
```

Для статичного часового аналізу задано тактове обмеження:

```tcl
create_clock -period 10.000 -name sys_clk [get_ports {clk}]
```

Період, заданий **для статичного часового аналізу**, становить:

```text
T = 10 ns
```

що відповідає частоті:

```text
f = 1 / T
  = 1 / 10 ns
  = 100 MHz
```

Таким чином, Quartus перевіряє, чи може реалізована схема працювати при часовій вимозі, еквівалентній **100 МГц**.

Це значення є timing constraint для STA і не означає, що фізичний генератор конкретної плати обов'язково працює на частоті 100 МГц.

## Результат Timing Analyzer

Для FPGA:

```text
Cyclone IV E
EP4CE6E22C8
```

отримано:

```text
Worst-case Setup Slack = +0.337 ns
Worst-case Hold Slack  = +0.483 ns
Design-wide TNS        = 0.000 ns
```

Отже:

```text
WNS = +0.337 ns
```

Додатне значення WNS означає, що схема виконує setup timing requirement при заданому періоді 10 нс.

```text
WNS > 0
    |
    v
Timing requirement met
```

Скріншот результату:

```text
quartus-timing-analyzer-report-screenshots/
    ExprPlain-Clk-10000.png
```

---

# Частина 3 — Неконвеєризований та конвеєризований варіанти

Для порівняння реалізовано два варіанти одного математичного виразу:

```text
((a + b) * c) - d
```

Обидві реалізації мають зареєстровані входи:

```text
a_reg
b_reg
c_reg
d_reg
```

Це забезпечує наявність внутрішніх шляхів типу:

```text
register → register
```

які можуть бути коректно проаналізовані за заданим clock constraint.

---

## ExprPlain — без конвеєризації

У неконвеєризованому варіанті весь математичний вираз обчислюється між вхідними регістрами та регістром результату.

Структура critical path:

```text
Input registers
      |
      v
     ADD
      |
      v
 MULTIPLY
      |
      v
 SUBTRACT
      |
      v
Result register
```

Таким чином, між двома групами регістрів знаходиться довгий комбінаторний шлях:

```text
ADD → MULTIPLY → SUBTRACT
```

---

## ExprPipelined — з конвеєризацією

У конвеєризованому варіанті додано проміжний регістр `stage1`.

Структура стає такою:

```text
Input registers
      |
      v
     ADD
      |
      v
 MULTIPLY
      |
      v
stage1 register
      |
      v
 SUBTRACT
      |
      v
Result register
```

Проміжний регістр розділяє довгий комбінаторний шлях на два коротші register-to-register шляхи.

Додатково `d_reg` передається через `d_stage`, щоб значення `d` було синхронізоване з результатом першої pipeline stage.

---

# Однаковий Clock Constraint

Для коректного порівняння `ExprPlain` та `ExprPipelined` використано **однаковий** clock constraint:

```tcl
create_clock -period 8.000 -name sys_clk [get_ports {clk}]
```

Для статичного часового аналізу задано:

```text
T = 8 ns
```

що відповідає:

```text
f = 1 / 8 ns
  = 125 MHz
```

Таким чином, обидві реалізації перевіряються за абсолютно однакових timing requirements.

---

# Результат ExprPlain

Для неконвеєризованої реалізації отримано:

```text
Worst-case Setup Slack = -1.717 ns
Design-wide TNS        = -17.496 ns
```

Отже:

```text
WNS = -1.717 ns
```

Від'ємне значення WNS означає, що схема не встигає завершити проходження сигналу через critical path до наступного активного фронту `clk`.

```text
ADD → MULTIPLY → SUBTRACT
          |
          v
     path too long

WNS = -1.717 ns
```

Timing requirement при періоді 8 нс **не виконується**.

Скріншоти:

```text
quartus-timing-analyzer-report-screenshots/
    ExprPlain-Clk-8000-01.png
    ExprPlain-Clk-8000-02.png
```

---

# Результат ExprPipelined

Для конвеєризованої реалізації при тому самому періоді 8 нс отримано:

```text
Worst-case Setup Slack = +1.308 ns
Design-wide TNS        = 0.000 ns
```

Отже:

```text
WNS = +1.308 ns
```

Додатне значення WNS означає, що після додавання pipeline register схема виконує timing requirement.

```text
ADD → MULTIPLY
       |
       v
    register
       |
       v
   SUBTRACT
```

Timing requirement при періоді 8 нс **виконується**.

Скріншот:

```text
quartus-timing-analyzer-report-screenshots/
    ExprPipelined-Clk-8000-01.png
```

---

# Порівняння результатів

| Реалізація | Період | Частота STA | WNS | TNS | Timing |
|---|---:|---:|---:|---:|---|
| `ExprPlain` | 8 нс | 125 МГц | **-1.717 нс** | -17.496 нс | ❌ Не виконується |
| `ExprPipelined` | 8 нс | 125 МГц | **+1.308 нс** | 0.000 нс | ✅ Виконується |

Покращення Worst-case Setup Slack:

```text
ΔWNS = WNS_pipelined - WNS_plain

ΔWNS = 1.308 - (-1.717)

ΔWNS = +3.025 ns
```

Отже, після додавання проміжного pipeline register Worst-case Setup Slack покращився на:

```text
3.025 ns
```

При однаковому clock constraint:

```text
T = 8 ns
```

отримано:

```text
ExprPlain
WNS = -1.717 ns
      |
      v
     FAIL

       ↓ PIPELINING

ExprPipelined
WNS = +1.308 ns
      |
      v
     PASS
```

---

# Функціональна симуляція

Функціональна симуляція виконана в ModelSim.

Вона підтверджує, що обидві реалізації обчислюють однаковий математичний результат.

### Test case 1

```text
a = 5
b = 3
c = 4
d = 10
```

Обчислення:

```text
(5 + 3) * 4 - 10
= 8 * 4 - 10
= 32 - 10
= 22
```

Для pipeline:

```text
stage1 = 32
d_stage = 10

result = 32 - 10 = 22
```

Обидві реалізації повертають:

```text
result = 22
```

### Test case 2

```text
a = 10
b = 20
c = 2
d = 5
```

Обчислення:

```text
(10 + 20) * 2 - 5
= 30 * 2 - 5
= 60 - 5
= 55
```

Для pipeline:

```text
stage1 = 60
d_stage = 5

result = 60 - 5 = 55
```

Обидві реалізації повертають:

```text
result = 55
```

Скріншот симуляції:

```text
tb-results-screenshot/
    ExprPlain-ExprPipelined-Comparition-Result.png
```

---

# Вплив конвеєризації

Конвеєризація не змінює математичний результат:

```text
ExprPlain      result = X
ExprPipelined  result = X
```

але змінює часові характеристики реалізації.

Без pipeline:

```text
Register
   |
   +--> ADD --> MULTIPLY --> SUBTRACT --> Register
```

З pipeline:

```text
Register
   |
   +--> ADD --> MULTIPLY --> Register
                              |
                              +--> SUBTRACT --> Register
```

Перевагою є скорочення максимального комбінаторного шляху між регістрами.

Недоліком є збільшення latency:

```text
ExprPlain      → результат раніше
ExprPipelined  → результат на 1 такт пізніше
```

Таким чином, pipeline дозволяє підвищити допустиму тактову частоту ціною додаткової затримки в один такт.

---

# Висновок

У роботі було:

1. Реалізовано FSM-контролер замка з debounce-фільтром та testbench.
2. Виконано Static Timing Analysis у Quartus Prime для FPGA `EP4CE6E22C8`.
3. Отримано числове значення WNS при clock constraint 10 нс.
4. Реалізовано неконвеєризований та конвеєризований варіанти одного математичного виразу.
5. Виконано їх функціональне порівняння у ModelSim.
6. Виконано STA для обох реалізацій при однаковому clock constraint 8 нс.
7. Отримано:

```text
ExprPlain      WNS = -1.717 ns
ExprPipelined  WNS = +1.308 ns
```

Таким чином, додавання проміжного pipeline register скоротило critical combinational path та дозволило виконати timing requirements при тому самому заданому тактовому періоді.