# Projet VHDL — Processeur RISC-V 32 bits monocycle (RV32I simplifié)

> **Un compte-rendu global est demandé pour ce projet.**

L'objectif de ces séances est de concevoir et de simuler le cœur d'un processeur **RISC-V 32 bits monocycle**, implémentant un sous-ensemble du jeu d'instructions de base **RV32I**. Ce processeur sera assemblé à partir de composants de base : registres, multiplexeurs, bancs de mémoire, générateur d'immédiats et Unité Arithmétique et Logique. Ces éléments seront intégrés pour former les différents blocs du système : l'**unité de traitement**, l'**unité de gestion des instructions** et l'**unité de contrôle**.

Le fonctionnement du processeur sera d'abord vérifié par la simulation de l'exécution d'un programme de test simple, puis testé sur FPGA.

Pour chaque conception, les circuits seront décrits en **VHDL comportemental** et simulés à l'aide de **ModelSim** (ou **GHDL / GTKWave**), en utilisant un banc de test spécialement développé pour cela.

### Compétences visées

- Rendre compte de son travail par la rédaction d'un compte-rendu de projet.
- Concevoir, synthétiser et valider une IP numérique décrite en VHDL RTL.

### Sous-ensemble RV32I implémenté

| Instruction | Format | Opération |
|---|---|---|
| `LUI  rd, imm`        | U | `rd ← imm << 12` |
| `ADDI rd, rs1, imm`   | I | `rd ← rs1 + SignExt(imm)` |
| `ADD  rd, rs1, rs2`   | R | `rd ← rs1 + rs2` |
| `SUB  rd, rs1, rs2`   | R | `rd ← rs1 − rs2` |
| `LW   rd, imm(rs1)`   | I | `rd ← DMEM[rs1 + SignExt(imm)]` |
| `SW   rs2, imm(rs1)`  | S | `DMEM[rs1 + SignExt(imm)] ← rs2` |
| `BEQ  rs1, rs2, off`  | B | `si rs1 = rs2 : PC ← PC + off` |
| `BNE  rs1, rs2, off`  | B | `si rs1 ≠ rs2 : PC ← PC + off` |
| `BLT  rs1, rs2, off`  | B | `si rs1 < rs2 (signé) : PC ← PC + off` |
| `JAL  rd, off`        | J | `rd ← PC + 4 ; PC ← PC + off` |
| `MRET` (partie 6)     | — | retour de sous-programme d'interruption |

> **Différences importantes avec un processeur de type ARM :**
> - RISC-V n'a **pas de registre d'état (drapeaux N, Z…)** : les branchements comparent directement deux registres dans le cycle même.
> - Le registre `x0` vaut **toujours 0** (les écritures dans `x0` sont ignorées).
> - Les adresses sont des **adresses d'octets** : le PC avance de **4** à chaque instruction, et les mémoires (organisées en mots de 32 bits) sont indexées par les bits `[7:2]` de l'adresse.
> - Les champs `rs1`, `rs2`, `rd` sont **toujours à la même position** dans l'instruction, ce qui simplifie le décodage.

---

## PARTIE 1 — UNITÉ DE TRAITEMENT

L'unité de traitement est principalement composée d'une Unité Arithmétique et Logique, d'un banc de registres et d'une mémoire de données, ainsi que de composants annexes (multiplexeurs, générateur d'immédiats…).

### Unité Arithmétique et Logique (UAL / ALU)

L'UAL 32 bits possède :

- `ALUCtrl` : signal de commande sur **3 bits**
- `A`, `B` : deux bus 32 bits en entrée
- `S` : bus 32 bits en sortie
- `Z` : drapeau sur 1 bit, vaut 1 si le résultat `S` est égal à zéro
- `LT` : drapeau sur 1 bit, vaut 1 si `A < B` en comparaison **signée**
- `LTU` : drapeau sur 1 bit, vaut 1 si `A < B` en comparaison **non signée**

Les valeurs de `ALUCtrl` déterminent l'opération réalisée :

| ALUCtrl | Opération | Résultat |
|---|---|---|
| `000` | ADD   | `S = A + B` |
| `001` | SUB   | `S = A − B` |
| `010` | AND   | `S = A and B` |
| `011` | OR    | `S = A or B` |
| `100` | XOR   | `S = A xor B` |
| `101` | SLT   | `S = 1 si A < B (signé), 0 sinon` |
| `110` | SLTU  | `S = 1 si A < B (non signé), 0 sinon` |
| `111` | COPY B| `S = B` (utilisé par `LUI`) |

> **Conseil :** la librairie `ieee.numeric_std.all` permet d'utiliser les opérateurs `+`, `-` et `<` sur les types `signed` et `unsigned`.
>
> **Attention :** pour `LT`, ne pas se contenter du bit de signe de `A − B` : en cas de dépassement, ce bit est faux. Utilisez une vraie comparaison `signed(A) < signed(B)`.

### Banc de registres

Le banc possède **32 registres de 32 bits** (`x0` à `x31`). Il comporte les entrées/sorties suivantes :

- `CLK` : horloge
- `Reset` : reset asynchrone (actif à l'état haut)
- `W` : bus de données en écriture sur 32 bits
- `RA` : bus d'adresse en lecture du port A sur **5 bits** (`rs1`)
- `RB` : bus d'adresse en lecture du port B sur **5 bits** (`rs2`)
- `RW` : bus d'adresse en écriture sur **5 bits** (`rd`)
- `WE` : Write Enable sur 1 bit
- `A` : bus de données en lecture du port A
- `B` : bus de données en lecture du port B

La **lecture** se fait de manière **asynchrone et simultanée** :

- le bus `A` prend la valeur du registre n° `RA` ;
- le bus `B` prend la valeur du registre n° `RB`.

L'**écriture** se fait de manière **synchrone**, sur le front montant de l'horloge, et est commandée par `WE` :

- si `WE = 1`, au front montant on recopie `W` dans le registre n° `RW`, **sauf si `RW = 0`** ;
- si `WE = 0`, aucune écriture n'est effectuée.

**Le registre `x0` doit toujours être lu à 0.**

#### 1.1 Travail à réaliser

**1.1.1** Décrire et simuler ces modules en VHDL comportemental à l'aide d'un banc de test et d'un script de simulation. Reporter les résultats de simulation dans le compte-rendu.

Le banc de registres sera déclaré comme un tableau de `std_logic_vector`. Son initialisation sera réalisée à l'aide d'une fonction :

```vhdl
-- Déclaration du type tableau
type table is array(31 downto 0) of std_logic_vector(31 downto 0);

-- Fonction d'initialisation du banc de registres
function init_banc return table is
    variable result : table;
begin
    for i in 30 downto 0 loop
        result(i) := (others => '0');
    end loop;
    result(31) := X"00000030";   -- x31 : utilisé plus tard comme pointeur de pile
    return result;
end init_banc;

-- Déclaration et initialisation du banc 32x32 bits
signal Banc : table := init_banc;
```

> **Conseil :** il faut impérativement éviter que l'indice du tableau soit négatif, non initialisé (`'U'`, `'X'`) ou supérieur à la taille du tableau. Si un de ces cas se produit, la simulation s'arrêtera sur une erreur fatale.

**1.1.2** Assembler l'UAL et le banc de registres (sortie `S` de l'UAL rebouclée sur l'entrée `W` du banc, `A` et `B` du banc reliés aux entrées de l'UAL) pour valider l'unité de traitement.

```
          RA ──►┌───────────┐ A ──────────►┌───────┐
          RB ──►│   Banc    │              │  UAL  │── S ──┐
          RW ──►│ 32 x 32   │ B ──────────►│       │       │
          WE ──►│           │              └───────┘       │
      ┌──► W ──►└───────────┘                 ▲ ALUCtrl    │
      └──────────────────────────────────────────────────────┘
```

**1.1.3** Écrire un banc de test et un script de simulation pour valider le bon fonctionnement des opérations suivantes (`x31 = 0x30` à l'initialisation) :

- `x1 = x31`
- `x1 = x1 + x31`
- `x2 = x1 + x31`
- `x3 = x1 − x31`
- `x5 = x7 − x31`
- tentative d'écriture de `x31` dans `x0`, puis vérification que `x0` vaut toujours 0

Reporter les résultats de simulation dans le compte-rendu. Pour la vérification de ces opérations, il est conseillé d'utiliser des **alias** et des **assertions**, toujours plus efficaces qu'une vérification visuelle des chronogrammes.

### Multiplexeurs

**Multiplexeur 2 vers 1** — paramètre générique `N` fixant la taille des données :

- `A`, `B` : deux bus sur N bits en entrée
- `COM` : commande de sélection sur 1 bit
- `S` : bus sur N bits en sortie

| COM | Opération |
|---|---|
| 0 | `S = A` |
| 1 | `S = B` |

**Multiplexeur 3 vers 1** — paramètre générique `N` :

- `A`, `B`, `C` : trois bus sur N bits en entrée
- `COM` : commande de sélection sur 2 bits
- `S` : bus sur N bits en sortie

| COM | Opération |
|---|---|
| `00` | `S = A` |
| `01` | `S = B` |
| `10` | `S = C` |
| `11` | `S = A` (valeur par défaut) |

### Extension de signe

Ce module étend sur 32 bits le signe d'une entrée codée sur N bits. Il possède un paramètre générique fixant la valeur de N :

- `E` : bus sur N bits en entrée
- `S` : bus sur 32 bits en sortie

### Générateur d'immédiats (ImmGen)

En RISC-V, la valeur immédiate est dispersée dans l'instruction de façon différente selon le format. Ce module combinatoire reconstruit l'immédiat sur 32 bits à partir de l'instruction, en s'appuyant sur le module d'extension de signe.

- `Instr` : instruction sur 32 bits
- `ImmSel` : sélection du format sur 3 bits
- `Imm` : immédiat sur 32 bits en sortie

| ImmSel | Format | Immédiat reconstruit (concaténation, bit de poids fort à gauche) |
|---|---|---|
| `000` | I | `SignExt( Instr[31:20] )` |
| `001` | S | `SignExt( Instr[31:25] & Instr[11:7] )` |
| `010` | B | `SignExt( Instr[31] & Instr[7] & Instr[30:25] & Instr[11:8] & '0' )` |
| `011` | U | `Instr[31:12] & x"000"` |
| `100` | J | `SignExt( Instr[31] & Instr[19:12] & Instr[20] & Instr[30:21] & '0' )` |

> Le bit 31 de l'instruction est **toujours** le bit de signe de l'immédiat, quel que soit le format.

### Mémoire de données

Cette mémoire permet de charger et stocker **64 mots de 32 bits**. Elle comporte les entrées/sorties suivantes :

- `CLK` : horloge
- `Reset` : reset asynchrone (actif à l'état haut)
- `DataIn` : bus de données en écriture sur 32 bits
- `DataOut` : bus de données en lecture sur 32 bits
- `Addr` : bus d'adresse **mot** sur 6 bits
- `WrEn` : Write Enable sur 1 bit

La lecture se fait de manière **asynchrone** : `DataOut` porte la valeur du mot n° `Addr`.

L'écriture se fait de manière **synchrone**, sur le front montant de l'horloge :

- si `WrEn = 1`, au front montant on recopie `DataIn` dans le mot n° `Addr` ;
- si `WrEn = 0`, aucune écriture n'est effectuée.

> **Conseil :** ce module est très proche du banc de registres et peut être conçu à partir de ce dernier.
>
> **Adressage :** le processeur calcule des adresses d'**octets**. Seuls les accès alignés sur 32 bits (`LW` / `SW`) sont gérés : l'adresse mot est donc `AdresseOctet[7:2]`.

#### 1.2 Travail à réaliser

**1.2.1** Décrire et simuler ces modules (multiplexeurs, extension de signe, ImmGen, mémoire de données) en VHDL comportemental. Reporter les résultats de simulation dans le compte-rendu. Pour l'ImmGen, vérifier au moins un immédiat **négatif** pour chacun des formats I, S, B et J.

### 1.3 Assemblage de l'unité de traitement

Les modules décrits précédemment doivent être assemblés conformément au schéma ci-dessous :

```
                  ┌───────────┐ A ─────────────────────►┌───────┐
  Instr[19:15] ──►│RA         │                          │       │ S         ┌──────────────┐
  Instr[24:20] ──►│RB  Banc   │ B ──┬──►┌──────┐         │  UAL  │──┬───────►│Addr  Mémoire │
  Instr[11:7]  ──►│RW  32x32  │     │   │ MUX  │────────►│       │  │ [7:2]  │     données  │
  RegWrite     ──►│WE         │     │   │ALUSrc│         └───────┘  │        │              │
            ┌────►│W          │     │   └──────┘           ▲ ALUCtrl│        │      DataOut │──┐
            │     └───────────┘     │      ▲ Imm (ImmGen)          │   ┌───►│DataIn        │  │
            │                       └──────┼───────────────────────┼───┘    │WrEn◄─MemWrite│  │
            │                              │                       │        └──────────────┘  │
            │                      ┌───────┴──────┐                │                          │
            └──────────────────────┤ MUX WrSrc    │◄── ALU (00) ───┘                          │
                                   │ (3 vers 1)   │◄── Mem (01) ──────────────────────────────┘
                                   │              │◄── PC+4 (10)  (depuis l'unité de gestion
                                   └──────────────┘               des instructions)
```

Le signal provenant de l'UAL étant sur 32 bits, la réduction vers les 6 bits de `Addr` peut être réalisée au niveau du port map :

```vhdl
Addr => AluOut(7 downto 2),
```

Pour l'instant, l'entrée `PC+4` du multiplexeur `WrSrc` peut être forcée à 0 dans le banc de test.

**1.3.1** Écrire un module VHDL effectuant l'assemblage de l'unité de traitement.

**1.3.2** Écrire un banc de test et un script de simulation pour valider le bon fonctionnement de :

- l'addition de 2 registres (`ADD`) ;
- l'addition d'un registre et d'une valeur immédiate positive puis négative (`ADDI`) ;
- la soustraction de 2 registres (`SUB`) ;
- le chargement d'une constante de poids fort (`LUI`) ;
- la copie de la valeur d'un registre dans un autre registre (`ADDI rd, rs1, 0`) ;
- l'écriture d'un registre dans un mot de la mémoire (`SW`) ;
- la lecture d'un mot de la mémoire dans un registre (`LW`).

Reporter les résultats de simulation dans le compte-rendu.

---

## PARTIE 2 — UNITÉ DE GESTION DES INSTRUCTIONS

L'unité de gestion des instructions 32 bits possède :

- une **mémoire d'instructions** de 64 mots de 32 bits, similaire à celle de l'unité de traitement (fournie en annexe : `instruction_memory.vhd`). Il n'y a ni bus de données en écriture ni Write Enable. Elle est indexée par `PC[7:2]` ;
- un **registre PC** 32 bits, avec horloge et reset asynchrone actif à l'état haut (valeur au reset : `0x00000000`) ;
- une entrée `Imm` sur 32 bits (immédiat de format B ou J, fourni par l'ImmGen) ;
- une sortie `PCplus4` sur 32 bits (adresse de retour pour `JAL`) ;
- une sortie `Instruction` sur 32 bits ;
- une unité de mise à jour du PC suivant le signal de contrôle `PCSrc` :
  - si `PCSrc = 0` alors `PC ← PC + 4`
  - si `PCSrc = 1` alors `PC ← PC + Imm`

> **Attention :** contrairement à ARM, la cible d'un branchement RISC-V est calculée par rapport à l'adresse **de l'instruction de branchement elle-même** (`PC + Imm`), et non `PC + 4 + Imm`.

Ce composant peut être décrit de manière complètement structurelle, ou en utilisant une description comportementale pour la partie de génération des nouvelles adresses.

**2.1** Décrire et simuler l'unité de gestion des instructions avec un banc de test et un script de simulation. Vérifier en particulier un saut vers l'arrière (immédiat négatif). Reporter les résultats de simulation dans le compte-rendu.

---

## PARTIE 3 — UNITÉ DE CONTRÔLE

L'unité de contrôle est constituée d'un **registre 32 bits avec commande de chargement** et d'un **décodeur combinatoire**.

### Registre 32 bits avec commande de chargement (RegAff)

RISC-V ne possédant pas de registre d'état, ce registre sert uniquement à mémoriser une valeur à afficher sur les LEDs ou les afficheurs 7 segments : il capture la donnée écrite en mémoire lors de chaque instruction `SW` (valeur du registre `rs2`).

Entrées/sorties :

- `DATAIN` : bus de chargement sur 32 bits
- `RST` : reset asynchrone, actif à l'état haut
- `CLK` : horloge
- `WE` : commande de chargement
- `DATAOUT` : bus de sortie sur 32 bits

Si `WE = 1`, le registre mémorise la valeur présente sur `DATAIN` au front montant. Si `WE = 0`, il conserve sa valeur précédente.

### Décodeur d'instructions

Ce module combinatoire génère les signaux de contrôle de l'unité de traitement, de l'unité de gestion des instructions et du registre RegAff. Leurs valeurs dépendent de l'instruction lue dans la mémoire d'instructions (champs `opcode`, `funct3`, `funct7` — voir annexe) et, **pour les branchements**, des drapeaux `Z` et `LT` de l'UAL calculés dans le même cycle.

Les commandes à générer concernent :

| Signal | Largeur | Rôle |
|---|---|---|
| `PCSrc`    | 1 | sélection du PC suivant : `0` = PC+4, `1` = PC+Imm |
| `RegWrite` | 1 | Write Enable du banc de registres |
| `ImmSel`   | 3 | format de l'immédiat (I, S, B, U, J) |
| `ALUSrc`   | 1 | entrée B de l'UAL : `0` = `rs2`, `1` = `Imm` |
| `ALUCtrl`  | 3 | opération de l'UAL |
| `MemWrite` | 1 | Write Enable de la mémoire de données |
| `WrSrc`    | 2 | donnée écrite dans le banc : `00` = UAL, `01` = mémoire, `10` = PC+4 |
| `RegAff`   | 1 | chargement du registre d'affichage (lors des `SW`) |

Les adresses `rs1`, `rs2` et `rd` sont prélevées directement dans l'instruction (bits `[19:15]`, `[24:20]` et `[11:7]`) : contrairement à l'architecture ARM, **aucun multiplexeur n'est nécessaire** sur l'adresse `RB` du banc.

Pour décrire ce décodeur, on déclarera tout d'abord le type énuméré suivant :

```vhdl
type enum_instruction is (I_LUI, I_ADDI, I_ADD, I_SUB, I_LW, I_SW,
                          I_BEQ, I_BNE, I_BLT, I_JAL, I_INVALID);
signal instr_courante : enum_instruction;
```

> Le préfixe `I_` évite les conflits avec les mots réservés VHDL (`and`, `or`, `xor`, `sll`…) si vous étendez plus tard le jeu d'instructions. `I_INVALID` permet de gérer proprement une instruction inconnue (aucune écriture, PC ← PC+4).

On pourra ensuite utiliser deux process dans l'architecture :

- un process sensible à la sortie de la mémoire d'instructions, dont le rôle est de fixer la valeur de `instr_courante` à partir de `opcode`, `funct3` et `funct7` ;
- un process sensible à `instr_courante` et aux drapeaux `Z` / `LT`, qui fixe la valeur des commandes.

**3.1** Compléter le tableau « Valeurs des commandes » ci-dessous, qui synthétise les actions du décodeur en fonction des instructions (la ligne `ADD` est donnée en exemple ; noter `X` quand la valeur est indifférente).

**3.2** Décrire en VHDL les deux modules de l'unité de contrôle : le décodeur d'instructions et le registre RegAff 32 bits.

### Valeurs des commandes

| Instruction | PCSrc | RegWrite | ImmSel | ALUSrc | ALUCtrl | MemWrite | WrSrc | RegAff |
|---|---|---|---|---|---|---|---|---|
| ADD  | 0 | 1 | X | 0 | 000 | 0 | 00 | 0 |
| SUB  |   |   |   |   |     |   |    |   |
| ADDI |   |   |   |   |     |   |    |   |
| LUI  |   |   |   |   |     |   |    |   |
| LW   |   |   |   |   |     |   |    |   |
| SW   |   |   |   |   |     |   |    |   |
| BEQ  |   |   |   |   |     |   |    |   |
| BNE  |   |   |   |   |     |   |    |   |
| BLT  |   |   |   |   |     |   |    |   |
| JAL  |   |   |   |   |     |   |    |   |

> Pour les branchements, `PCSrc` dépend du résultat de la comparaison (`Z` ou `LT`) : exprimez-le sous forme d'équation dans le tableau.

---

## PARTIE 4 — ASSEMBLAGE ET VALIDATION DU PROCESSEUR

Il faut à présent finaliser la modélisation du processeur en assemblant ses trois unités principales :

- l'unité de gestion des instructions ;
- l'unité de traitement ;
- l'unité de contrôle.

### Schéma global du processeur

```
 ┌──────────── Unité de gestion des instructions ────────────┐
 │  ┌────┐   ┌──────────────┐                                │
 │  │ PC │──►│ Mémoire      │── Instruction[31:0] ───────────┼──┬──────────────────────┐
 │  └────┘   │ instructions │                                │  │                      │
 │   ▲       └──────────────┘                                │  ▼                      ▼
 │   └── MUX (PC+4 / PC+Imm) ◄── PCSrc                       │ ┌──────────┐     ┌──────────┐
 └──────────────────┬──────────────────────▲─────────────────┘ │ Décodeur │     │  ImmGen  │
                    │ PC+4                 │ Imm                └──────────┘     └──────────┘
                    ▼                      │                     │ commandes       │ Imm
 ┌──────────────────────────── Unité de traitement ───────────────────────────────┴──────┐
 │  Banc de registres ── UAL ── Mémoire de données ── MUX WrSrc (UAL / Mem / PC+4)      │
 │                       │ Z, LT ──► Décodeur                                            │
 └───────────────────────────────────────────────────────────────────────────────────────┘
                                rs2 ──► RegAff (chargé lors des SW) ──► afficheurs
```

**4.1** Compléter l'unité de traitement conçue précédemment en reliant l'entrée `PC+4` du multiplexeur `WrSrc` à la sortie `PCplus4` de l'unité de gestion des instructions (nécessaire pour `JAL`).

**4.2** Assembler le processeur à partir de ses trois unités.

**4.3** Simuler l'exécution du programme de test par le processeur et vérifier son bon fonctionnement.

Il sera nécessaire d'initialiser quelques données dans la mémoire de données : les mots d'indice `16` à `25` (adresses d'octets `0x40` à `0x64`), par exemple avec les valeurs 1 à 10.

### Programme de test

```asm
# Adr   Étiquette   Instruction            Commentaire
0x00    _main:      addi x1, x0, 0x40      # x1 <= 0x40  (pointeur sur les données)
0x04                addi x2, x0, 0         # x2 <= 0     (somme)
0x08                addi x3, x0, 0x68      # x3 <= 0x68  (adresse de fin)
0x0C    _loop:      lw   x10, 0(x1)        # x10 <= DMEM[x1]
0x10                add  x2, x2, x10       # x2 <= x2 + x10
0x14                addi x1, x1, 4         # x1 <= x1 + 4 (mot suivant)
0x18                blt  x1, x3, _loop     # si x1 < x3 : retour à _loop (offset −12)
0x1C    _end:       sw   x2, 0(x1)         # DMEM[x1] <= x2 ; RegAff <= x2
0x20                jal  x0, _main         # retour à _main (offset −32)
```

Avec les valeurs 1 à 10 en mémoire, la somme attendue est `55 = 0x37`, écrite à l'adresse `0x68` (mot d'indice 26) et chargée dans RegAff.

---

## PARTIE 5 — TEST DU PROCESSEUR SUR CARTE FPGA

Dans cette partie, vous allez implémenter votre processeur monocycle sur une carte FPGA.

Pour vérifier que l'exécution du programme de test se fait sans erreur, vous afficherez sur les afficheurs 7 segments la valeur en sortie du registre **RegAff**. Pour cela, il faut ajouter 4 décodeurs 7 segments pour décoder les bits 0 à 15 de RegAff afin d'afficher cette valeur en hexadécimal sur 4 digits.

### Travail à réaliser

**5.1** Créer un projet sur Quartus, instancier le processeur et les 4 décodeurs 7 segments dans un fichier `top_level.vhd`. Faire l'assignation des pins, lancer la synthèse et programmer la carte.

**5.2** Vérifier que vous trouvez la valeur attendue (`0037`) sur les afficheurs 7 segments.

> **Conseil :** l'horloge de la carte (50 MHz typiquement) peut être utilisée directement, ou divisée pour observer l'évolution du programme. Le reset peut être relié à un bouton poussoir (attention à la polarité).

---

## PARTIE 6 — GESTION DES INTERRUPTIONS EXTERNES

Pour gérer les interruptions externes, il faut ajouter un **contrôleur d'interruptions vectorisé** (VIC, *Vectored Interrupt Controller*).

Il faudra également modifier le décodeur d'instructions afin de décoder l'instruction **`MRET`**, qui se trouve à la fin d'un sous-programme d'interruption et signifie qu'il faut revenir au programme interrompu. Enfin, il faudra modifier l'unité de gestion des instructions pour prendre en compte les interruptions.

> Dans un vrai RISC-V, les interruptions sont gérées par les registres CSR du mode machine (`mtvec`, `mepc`, `mstatus`, `mcause`…). On en implémente ici une version simplifiée : un seul registre **`MEPC`** et des vecteurs fournis par le VIC.

### 6.1 VIC : contrôleur d'interruptions vectorisé

**Entrées :**

- `CLK` : horloge
- `RESET` : reset asynchrone, actif à l'état haut
- `IRQ_SERV` : acquittement de l'interruption venant de l'unité de gestion des instructions
- `IRQ0`, `IRQ1` : requêtes d'interruption externes

**Sorties :**

- `IRQ` : requête d'interruption envoyée à l'unité de gestion des instructions
- `VICPC` : adresse de début du sous-programme d'interruption (32 bits)

**Fonctionnement :**

- Le module échantillonne `IRQ0` et `IRQ1` afin de connaître la dernière (`IRQi(n)`) et l'avant-dernière (`IRQi(n−1)`) valeur de ces signaux.
- Si une transition montante est détectée (`IRQi(n) = 1` et `IRQi(n−1) = 0`), on force à 1 le signal `IRQ0_memo` ou `IRQ1_memo`, signalant une requête d'interruption.
- `IRQ0_memo` et `IRQ1_memo` restent à 1 tant qu'aucun acquittement n'est reçu sur `IRQ_SERV`.
- S'il n'y a aucune requête, `VICPC` est forcé à 0.
- Si `IRQ0_memo = 1`, `VICPC` vaut **`0x24`** (adresse de début de l'ISR 0).
- Si `IRQ1_memo = 1`, `VICPC` vaut **`0x54`** (adresse de début de l'ISR 1).
- `IRQ0` est prioritaire sur `IRQ1`.
- La sortie `IRQ` est le OU logique de `IRQ0_memo` et `IRQ1_memo`.

**À faire :**

**6.1.1** Créer une nouvelle source VHDL décrivant le VIC.

**6.1.2** Simuler ce composant à l'aide d'un banc de test et d'un script de simulation.

### 6.2 Modification du décodeur d'instructions

Pour sortir d'un sous-programme d'interruption, on utilise l'instruction **`MRET`**, dont le code binaire est **`0x30200073`**.

Ajouter un signal de contrôle en sortie de l'entité du décodeur :

- `IRQ_END` : mis à 1 lorsque l'instruction `MRET` est exécutée.

Ajouter `I_MRET` au type énuméré et la ligne correspondante au tableau des commandes (aucune écriture registre ni mémoire).

### 6.3 Modification de l'unité de gestion des instructions

Ajouter les signaux suivants à l'entité :

**Entrées :**

- `IRQ` : si actif, signale une nouvelle interruption (généré par le VIC)
- `VICPC` : adresse (vecteur) du sous-programme d'interruption
- `IRQ_END` : si actif, indique la fin du sous-programme d'interruption

**Sortie :**

- `IRQ_SERV` : acquittement de l'interruption lorsqu'elle a été prise en compte

**Fonctionnement :**

- Lorsqu'une interruption est active (`IRQ = 1`), il faut copier `VICPC` dans `PC` et, **au même front d'horloge**, sauvegarder dans un registre **`MEPC`** l'adresse de l'instruction qui aurait dû être exécutée ensuite (le PC suivant normalement calculé : PC+4 ou cible de branchement).
- Lorsque l'interruption est prise en compte, mettre `IRQ_SERV` à 1, et le laisser à 0 le reste du temps.
- Lorsque `IRQ_END` est actif, recharger `PC` avec la valeur de `MEPC` afin que le programme principal reprenne.
- Attention au timing des signaux pour que **chaque instruction ne s'exécute qu'une seule fois**.

> **Conseil :** ajoutez un bit interne « ISR en cours », mis à 1 à la prise en compte d'une interruption et remis à 0 par `MRET`, pour ignorer `IRQ` pendant l'exécution d'un sous-programme d'interruption (pas d'imbrication d'interruptions, `MEPC` n'étant pas sauvegardé).

### 6.4 Test par simulation

Simuler le processeur avec le VIC à l'aide d'un banc de test et d'un script de simulation (programme de l'annexe `instruction_memory_IRQ.vhd`). Vérifier que chaque `IRQ0` incrémente de 1 le mot à l'adresse `0x40`, que chaque `IRQ1` l'incrémente de 2, et que la somme calculée par le programme principal évolue en conséquence. Reporter les résultats de simulation dans le compte-rendu.

### 6.5 Test du VIC sur FPGA

Implémenter le processeur avec le VIC sur FPGA (`IRQ0` et `IRQ1` reliés à des boutons poussoirs) et vérifier qu'il fonctionne correctement.

> **Attention :** un bouton poussoir mécanique produit des rebonds ; prévoyez un anti-rebond, sinon un appui peut générer plusieurs interruptions.

---

## ANNEXES

### A. Formats d'instructions RV32I

```
 31        25 24    20 19    15 14  12 11         7 6        0
┌────────────┬────────┬────────┬──────┬────────────┬──────────┐
│   funct7   │  rs2   │  rs1   │funct3│     rd     │  opcode  │  R
├────────────┴────────┼────────┼──────┼────────────┼──────────┤
│      imm[11:0]      │  rs1   │funct3│     rd     │  opcode  │  I
├────────────┬────────┼────────┼──────┼────────────┼──────────┤
│ imm[11:5]  │  rs2   │  rs1   │funct3│  imm[4:0]  │  opcode  │  S
├────────────┼────────┼────────┼──────┼────────────┼──────────┤
│imm[12|10:5]│  rs2   │  rs1   │funct3│imm[4:1|11] │  opcode  │  B
├────────────┴────────┴────────┴──────┼────────────┼──────────┤
│             imm[31:12]              │     rd     │  opcode  │  U
├─────────────────────────────────────┼────────────┼──────────┤
│        imm[20|10:1|11|19:12]        │     rd     │  opcode  │  J
└─────────────────────────────────────┴────────────┴──────────┘
```

### B. Codage des instructions du sous-ensemble

| Instruction | opcode | funct3 | funct7 | Format |
|---|---|---|---|---|
| LUI  | `0110111` | —     | —         | U |
| JAL  | `1101111` | —     | —         | J |
| BEQ  | `1100011` | `000` | —         | B |
| BNE  | `1100011` | `001` | —         | B |
| BLT  | `1100011` | `100` | —         | B |
| LW   | `0000011` | `010` | —         | I |
| SW   | `0100011` | `010` | —         | S |
| ADDI | `0010011` | `000` | —         | I |
| ADD  | `0110011` | `000` | `0000000` | R |
| SUB  | `0110011` | `000` | `0100000` | R |
| MRET | `1110011` | `000` | `0011000` | instruction complète : `0x30200073` |

> `NOP` est codé `0x00000013` (`addi x0, x0, 0`).

### C. `instruction_memory.vhd` (programme de la partie 4)

```vhdl
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity instruction_memory is
    port(
        PC          : in  std_logic_vector(31 downto 0);
        Instruction : out std_logic_vector(31 downto 0)
    );
end entity;

architecture RTL of instruction_memory is
    type RAM64x32 is array (0 to 63) of std_logic_vector(31 downto 0);

    function init_mem return RAM64x32 is
        variable result : RAM64x32;
    begin
        for i in 63 downto 0 loop
            result(i) := (others => '0');
        end loop;
        --                         -- Adr   -- Instruction          -- Commentaire
        result(0) := x"04000093";  -- 0x00  -- addi x1, x0, 0x40    -- x1 = 0x40
        result(1) := x"00000113";  -- 0x04  -- addi x2, x0, 0       -- x2 = 0
        result(2) := x"06800193";  -- 0x08  -- addi x3, x0, 0x68    -- x3 = 0x68
        result(3) := x"0000A503";  -- 0x0C  -- lw   x10, 0(x1)      -- x10 = DMEM[x1]
        result(4) := x"00A10133";  -- 0x10  -- add  x2, x2, x10     -- x2 = x2 + x10
        result(5) := x"00408093";  -- 0x14  -- addi x1, x1, 4       -- x1 = x1 + 4
        result(6) := x"FE30CAE3";  -- 0x18  -- blt  x1, x3, -12     -- si x1 < x3 : PC = 0x0C
        result(7) := x"0020A023";  -- 0x1C  -- sw   x2, 0(x1)       -- DMEM[x1] = x2
        result(8) := x"FE1FF06F";  -- 0x20  -- jal  x0, -32         -- PC = 0x00
        return result;
    end init_mem;

    signal mem : RAM64x32 := init_mem;
begin
    Instruction <= mem(to_integer(unsigned(PC(7 downto 2))));
end architecture;
```

### D. `instruction_memory_IRQ.vhd` (programme de la partie 6)

Le registre `x31` (initialisé à `0x30`) sert de pointeur de pile pour la sauvegarde du contexte.

```vhdl
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity instruction_memory_IRQ is
    port(
        PC          : in  std_logic_vector(31 downto 0);
        Instruction : out std_logic_vector(31 downto 0)
    );
end entity;

architecture RTL of instruction_memory_IRQ is
    type RAM64x32 is array (0 to 63) of std_logic_vector(31 downto 0);

    function init_mem return RAM64x32 is
        variable ram_block : RAM64x32;
    begin
        ram_block := (others => x"00000000");
        --                              -- Adr  -- Instruction          -- Commentaire
        -- Programme principal
        ram_block(0)  := x"04000093";   -- 0x00 -- addi x1, x0, 0x40    -- x1 = 0x40
        ram_block(1)  := x"00000113";   -- 0x04 -- addi x2, x0, 0       -- x2 = 0
        ram_block(2)  := x"06800193";   -- 0x08 -- addi x3, x0, 0x68    -- x3 = 0x68
        ram_block(3)  := x"0000A503";   -- 0x0C -- lw   x10, 0(x1)      -- x10 = DMEM[x1]
        ram_block(4)  := x"00A10133";   -- 0x10 -- add  x2, x2, x10     -- x2 = x2 + x10
        ram_block(5)  := x"00408093";   -- 0x14 -- addi x1, x1, 4       -- x1 = x1 + 4
        ram_block(6)  := x"FE30CAE3";   -- 0x18 -- blt  x1, x3, -12     -- si x1 < x3 : PC = 0x0C
        ram_block(7)  := x"0020A023";   -- 0x1C -- sw   x2, 0(x1)       -- DMEM[x1] = x2
        ram_block(8)  := x"FE1FF06F";   -- 0x20 -- jal  x0, -32         -- PC = 0x00

        -- ISR 0 (vecteur 0x24)
        -- sauvegarde du contexte
        ram_block(9)  := x"001FA023";   -- 0x24 -- sw   x1, 0(x31)      -- DMEM[x31] = x1
        ram_block(10) := x"004F8F93";   -- 0x28 -- addi x31, x31, 4     -- x31 = x31 + 4
        ram_block(11) := x"003FA023";   -- 0x2C -- sw   x3, 0(x31)      -- DMEM[x31] = x3
        -- traitement
        ram_block(12) := x"04000193";   -- 0x30 -- addi x3, x0, 0x40    -- x3 = 0x40
        ram_block(13) := x"0001A083";   -- 0x34 -- lw   x1, 0(x3)       -- x1 = DMEM[x3]
        ram_block(14) := x"00108093";   -- 0x38 -- addi x1, x1, 1       -- x1 = x1 + 1
        ram_block(15) := x"0011A023";   -- 0x3C -- sw   x1, 0(x3)       -- DMEM[x3] = x1
        -- restauration du contexte
        ram_block(16) := x"000FA183";   -- 0x40 -- lw   x3, 0(x31)      -- x3 = DMEM[x31]
        ram_block(17) := x"FFCF8F93";   -- 0x44 -- addi x31, x31, -4    -- x31 = x31 - 4
        ram_block(18) := x"000FA083";   -- 0x48 -- lw   x1, 0(x31)      -- x1 = DMEM[x31]
        ram_block(19) := x"30200073";   -- 0x4C -- mret                 -- fin d'interruption
        ram_block(20) := x"00000013";   -- 0x50 -- nop

        -- ISR 1 (vecteur 0x54)
        -- sauvegarde du contexte
        ram_block(21) := x"004FA023";   -- 0x54 -- sw   x4, 0(x31)      -- DMEM[x31] = x4
        ram_block(22) := x"004F8F93";   -- 0x58 -- addi x31, x31, 4     -- x31 = x31 + 4
        ram_block(23) := x"005FA023";   -- 0x5C -- sw   x5, 0(x31)      -- DMEM[x31] = x5
        -- traitement
        ram_block(24) := x"04000293";   -- 0x60 -- addi x5, x0, 0x40    -- x5 = 0x40
        ram_block(25) := x"0002A203";   -- 0x64 -- lw   x4, 0(x5)       -- x4 = DMEM[x5]
        ram_block(26) := x"00220213";   -- 0x68 -- addi x4, x4, 2       -- x4 = x4 + 2
        ram_block(27) := x"0042A023";   -- 0x6C -- sw   x4, 0(x5)       -- DMEM[x5] = x4
        -- restauration du contexte
        ram_block(28) := x"000FA283";   -- 0x70 -- lw   x5, 0(x31)      -- x5 = DMEM[x31]
        ram_block(29) := x"FFCF8F93";   -- 0x74 -- addi x31, x31, -4    -- x31 = x31 - 4
        ram_block(30) := x"000FA203";   -- 0x78 -- lw   x4, 0(x31)      -- x4 = DMEM[x31]
        ram_block(31) := x"30200073";   -- 0x7C -- mret                 -- fin d'interruption
        return ram_block;
    end init_mem;

    signal mem : RAM64x32 := init_mem;
begin
    Instruction <= mem(to_integer(unsigned(PC(7 downto 2))));
end architecture;
```

### E. Pour aller plus loin (bonus)

- Étendre le décodeur aux autres instructions arithmétiques et logiques de RV32I (`AND`, `OR`, `XOR`, `SLT`, `SLTU` et leurs versions immédiates), déjà supportées par l'UAL.
- Ajouter `BGE`, `BLTU`, `BGEU` (drapeau `LTU` déjà disponible) et `JALR`.
- Écrire vos propres programmes en assembleur et les assembler avec la chaîne GNU (`riscv64-unknown-elf-as -march=rv32i`, puis `objcopy -O binary`) ou vérifier vos encodages avec un simulateur comme RARS ou Venus.
