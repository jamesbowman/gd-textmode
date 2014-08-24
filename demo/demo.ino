#include <SPI.h>

#define SELECT()    digitalWrite(9, 0)
#define UNSELECT()  digitalWrite(9, 1)

void setup()
{
  SPI.begin();
  pinMode(9, OUTPUT);
  UNSELECT();
}

static byte scroll;

void start(int addr)
{
  SELECT();
  SPI.transfer(scroll);
  SPI.transfer(addr >> 8);
  SPI.transfer(addr);
}

void cls()
{
  start(0);
  for (uint16_t i = (128 * 128 * 2); i; i--)
    SPI.transfer(0);
  UNSELECT();
}

void xloop()
{
  cls();
  for (int a = 30; a < 10000; a += 256) {
    start(a);
    for (int attr = 0; attr < 16; attr++) {
      SPI.transfer('*');
      SPI.transfer(attr);
    }

    SPI.transfer(0);
    SPI.transfer(0);

    for (int attr = 0; attr < 256; attr += 16) {
      SPI.transfer('*');
      SPI.transfer(attr);
    }
    UNSELECT();
  }
  delay(1000);
}

void demo_random()
{
  cls();
  for (uint16_t i = 0; i < 60000; i++) {
    int a = random(128 * 48);
    start(2 * a);
    SPI.transfer(random(256));
    SPI.transfer(random(256));
    UNSELECT();
  }
}

void at(byte x, byte y, byte color, const char *s)
{
  start(256 * y + 2 * x);
  while (*s) {
    SPI.transfer(*s++);
    SPI.transfer(color);
  }
  UNSELECT();
}

prog_char book[] PROGMEM =
"A TALE OF TWO CITIES\n"
"\n"
"A STORY OF THE FRENCH REVOLUTION\n"
"\n"
"By Charles Dickens\n"
"\n"
"Book the First--Recalled to Life\n"
"\n"
"I. The Period\n"
"\n"
"It was the best of times,\n"
"it was the worst of times,\n"
"it was the age of wisdom,\n"
"it was the age of foolishness,\n"
"it was the epoch of belief,\n"
"it was the epoch of incredulity,\n"
"it was the season of Light,\n"
"it was the season of Darkness,\n"
"it was the spring of hope,\n"
"it was the winter of despair,\n"
"we had everything before us,\n"
"we had nothing before us,\n"
"we were all going direct to Heaven,\n"
"we were all going direct the other way--\n"
"in short, the period was so far like the present period,\n"
"that some of its noisiest authorities insisted on its being\n"
"received, for good or for evil, in the superlative degree of\n"
"comparison only.\n"
"\n"
"There were a king with a large jaw and a queen with a plain\n"
"face, on the throne of England; there were a king with a large\n"
"jaw and a queen with a fair face, on the throne of France. In\n"
"both countries it was clearer than crystal to the lords of\n"
"the State preserves of loaves and fishes, that things in\n"
"general were settled for ever.\n"
"\n"
"It was the year of Our Lord one thousand seven hundred\n"
"and seventy-five.  Spiritual revelations were conceded to\n"
"England at that favoured period, as at this. Mrs. Southcott\n"
"had recently attained her five-and-twentieth blessed birthday,\n"
"of whom a prophetic private in the Life Guards had heralded\n"
"the sublime appearance by announcing that arrangements were\n"
"made for the swallowing up of London and Westminster. Even the\n"
"Cock-lane ghost had been laid only a round dozen of years,\n"
"after rapping out its messages, as the spirits of this very\n"
"year last past (supernaturally deficient in originality)\n"
"rapped out theirs. Mere messages in the earthly order of\n"
"events had lately come to the English Crown and People, from\n"
"a congress of British subjects in America: which, strange\n"
"to relate, have proved more important to the human race than\n"
"any communications yet received through any of the chickens\n"
"of the Cock-lane brood.\n"
"\n"
"France, less favoured on the whole as to matters spiritual than\n"
"her sister of the shield and trident, rolled with exceeding\n"
"smoothness down hill, making paper money and spending it. Under\n"
"the guidance of her Christian pastors, she entertained herself,\n"
"besides, with such humane achievements as sentencing a youth\n"
"to have his hands cut off, his tongue torn out with pincers,\n"
"and his body burned alive, because he had not kneeled down\n"
"in the rain to do honour to a dirty procession of monks\n"
"which passed within his view, at a distance of some fifty or\n"
"sixty yards. It is likely enough that, rooted in the woods\n"
"of France and Norway, there were growing trees, when that\n"
"sufferer was put to death, already marked by the Woodman,\n"
"Fate, to come down and be sawn into boards, to make a certain\n"
"movable framework with a sack and a knife in it, terrible\n"
"in history. It is likely enough that in the rough outhouses\n"
"of some tillers of the heavy lands adjacent to Paris, there\n"
"were sheltered from the weather that very day, rude carts,\n"
"bespattered with rustic mire, snuffed about by pigs, and\n"
"roosted in by poultry, which the Farmer, Death, had already set\n"
"apart to be his tumbrils of the Revolution. But that Woodman\n"
"and that Farmer, though they work unceasingly, work silently,\n"
"and no one heard them as they went about with muffled tread:\n"
"the rather, forasmuch as to entertain any suspicion that they\n"
"were awake, was to be atheistical and traitorous.\n"
"\n"
"In England, there was scarcely an amount of order and\n"
"protection to justify much national boasting. Daring burglaries\n"
"by armed men, and highway robberies, took place in the capital\n"
"itself every night; families were publicly cautioned not to go\n"
"out of town without removing their furniture to upholsterers'\n"
"warehouses for security; the highwayman in the dark was a City\n"
"tradesman in the light, and, being recognised and challenged\n"
"by his fellow-tradesman whom he stopped in his character of\n"
"`the Captain,' gallantly shot him through the head and rode\n"
"away; the mail was waylaid by seven robbers, and the guard shot\n"
"three dead, and then got shot dead himself by the other four,\n"
"`in consequence of the failure of his ammunition:' after which\n"
"the mail was robbed in peace; that magnificent potentate,\n"
"the Lord Mayor of London, was made to stand and deliver on\n"
"Turnham Green, by one highwayman, who despoiled the illustrious\n"
"creature in sight of all his retinue; prisoners in London\n"
"gaols fought battles with their turnkeys, and the majesty of\n"
"the law fired blunderbusses in among them, loaded with rounds";

void demo_book()
{
  cls();
  char c;
  start(0);
  uint16_t y = 0;

  byte attr = 0x0f;
  char prev;
  for (prog_char *p = book; (c = pgm_read_byte(p)) != 0; p++) {
    if (c == '\n') {
      UNSELECT();
      ++y;
      start(256 * (y % 48) + 128 * (y / 48));
      prev = ' ';
    } else {
      if (prev == ' ') {
        if (c < 'Z')
          attr = 0x0f;
        else
          attr = 0x0a;
      }
      SPI.transfer(c);
      SPI.transfer(attr);
      prev = c;
    }
  }
  UNSELECT();
}

static void demo_colors()
{
  cls();
  for (byte j = 0; j < 16; j++)
    for (byte i = 0; i < 16; i++) {
      byte attr = (j << 4) | i;
      at(8 * j, 3 * i + 0, attr, "        ");
      at(8 * j, 3 * i + 1, attr, " *TEXT* ");
      at(8 * j, 3 * i + 2, attr, "        ");
    }
}

void loop()
{
  demo_colors();
  delay(4000);
  demo_book();
  delay(4000);
  demo_random();
}

class TTY: public Print {
    public:
      virtual size_t write(uint8_t character) {
      };
    private:
    // otherstuff
};
