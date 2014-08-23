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

void vga(int addr)
{
  SELECT();
  SPI.transfer(scroll);
  SPI.transfer(addr >> 8);
  SPI.transfer(addr);
}

void cls()
{
  vga(0);
  for (int i = 0; i < (128 * 48 * 2); i++)
    SPI.transfer(0);
  UNSELECT();
}

void xloop()
{
  cls();
  for (int a = 30; a < 10000; a += 256) {
    vga(a);
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

void loop()
{
  int a = random(128 * 48);
  vga(2 * a);
  SPI.transfer(random(256));
  SPI.transfer(random(256));
  UNSELECT();
}

class TTY: public Print {
    public:
      virtual size_t write(uint8_t character) {
      };
    private:
    // otherstuff
};
