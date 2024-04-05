library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.STD_LOGIC_ARITH.all;
  use IEEE.STD_LOGIC_UNSIGNED.all;

entity BitMapPatt is
  port (
    RstB        : in  std_logic;
    Clk         : in  std_logic;

    BmpFfWrData : out std_logic_vector(23 downto 0);
    BmpFfWrEn   : out std_logic;

    RxFfWrData  : in  std_logic_vector(7 downto 0);
    RxFfWrEn    : in  std_logic
  );
end entity;

architecture RTL of BitMapPatt is

  ----------------------------------------------------------------------------------
  -- Component declaration
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  -- Signal declaration
  ----------------------------------------------------------------------------------
  -- State machine
  signal rState : std_logic; -- State signal (0: header, 1: body)

  -- Bitmap Data Interface
  signal rBmpFfWrData : std_logic_vector(23 downto 0); -- Bitmap write data: data to be sent to FIFO

  -- Bitmap Control Interface
  signal rBmpFfWrEn : std_logic;                     -- Bitmap write enable: when 1 pixel data is ready, enable signal for FIFO
  signal rRgbWrCnt  : std_logic_vector(1 downto 0);  -- RGB controller: RGB counter for 1 pixel (0: 3 bytes, 1: 2 bytes, 2: 1 byte)
  signal rHeaderCnt : std_logic_vector(5 downto 0);  -- Header data counter: first 54 bytes (Don't care)
  signal rBodyCnt   : std_logic_vector(19 downto 0); -- Body data counter: 1024x768x3 bytes (Bitmap write data counter)

begin
  ----------------------------------------------------------------------------------
  -- Output assignment
  ----------------------------------------------------------------------------------
  BmpFfWrEn   <= rBmpFfWrEn;
  BmpFfWrData <= rBmpFfWrData;

  ----------------------------------------------------------------------------------
  -- DFF 
  ----------------------------------------------------------------------------------
  -- state machine

  u_rState: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rState <= '0';
      end if;
    else
      if (rState = '0') then
        -- if pass the header data part & fifo write is available, then body state is coming
        if (rHeaderCnt = 53 and RxFfWrEn = '1') then
          rState <= 1;
        else
          rState <= 0;
        end if;
      else
        -- if send all data & fifo write is available, then header state is coming
        if (rBodyCnt = 786431 and rRgbWrCnt = 0 and RxFfWrEn = '1') then
          rState <= 0;
        else
          rState <= 1;
        end if;
      end if;
    end if;
  end process;

  -- Store three 8-bit data to 24-bit data before send to FIFO

  u_rRxFfWrData: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rBmpFfWrData <= (others => '1');
      else
        -- if state is body & fifo is available, then store data
        if (rState = stBmpBody and RxFfWrEn = '1') then
          rBmpFfWrData <= RxFfWrData & rBmpFfWrData(23 downto 8);
        end if;
      end if;
    end if;
  end process;

  -- Bitmap write enable for FIFO

  u_rBmpFfWrEn: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rBmpFfWrEn <= '0';
      else
        -- if accumulate up to 1 pixel & fifo is available, then send enable for fifo
        if (rState = stBmpBody and rRgbWrCnt = 0 and RxFfWrEn = '1') then
          rBmpFfWrEn <= '1';
        else
          rBmpFfWrEn <= '0';
        end if;
      end if;
    end if;
  end process;

  -- RGB controller

  u_rRgbWrCnt: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rRgbWrCnt <= "10";
      else
        -- if state is body & fifo is available, then decrement counter (3 bytes RGB data)
        if (rState = 1 and RxFfWrEn = '1') then
          -- if counter is 1 (all RGB is send), then reset counter
          if (rRgbWrCnt = 0) then
            rRgbWrCnt <= "10";
          else
            rRgbWrCnt <= rRgbWrCnt - 1;
          end if;
        else
          rRgbWrCnt <= rRgbWrCnt;
        end if;
      end if;
    end if;
  end process;

  -- Header address counter for 54 bytes

  u_rHeaderCnt: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rHeaderCnt <= (others => '0');
      else
        -- if state is header & fifo write is available, then increment counter
        if (rState = 0 and RxFfWrEn = '1') then
          if (rHeaderCnt = 53) then
            rHeaderCnt <= (others => '0');
          else
            rHeaderCnt <= rHeaderCnt + 1;
          end if;
        else
          rHeaderCnt <= rHeaderCnt;
        end if;
      end if;
    end if;
  end process;

  -- Body address counter for 1024x768x3 bytes

  u_rBodyCnt: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rBodyCnt <= (others => '0');
      else
        -- 
        if (rState = '1' and RxFfWrEn = '1' and rRgbWrCnt = 0) then
          -- (1024 x 768)
          if (rBodyCnt = 786431) then
            rBodyCnt <= (others => '0');
          else
            rBodyCnt <= rBodyCnt + 1;
          end if;
        else
          rBodyCnt <= rBodyCnt;
        end if;
      end if;
    end if;
  end process;

end architecture;
