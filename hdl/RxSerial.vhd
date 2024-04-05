library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.STD_LOGIC_ARITH.all;
  use IEEE.STD_LOGIC_UNSIGNED.all;
  use IEEE.numeric_std.all;

entity RxSerial is
  port (
    RstB       : in  std_logic;
    Clk        : in  std_logic;

    SerDataIn  : in  std_logic;

    RxFfFull   : in  std_logic;
    RxFfWrData : out std_logic_vector(7 downto 0);
    RxFfWrEn   : out std_logic
  );
end entity;

architecture RxSerialBehavior of RxSerial is

  ----------------------------------------------------------------------------------
  -- Constant declaration
  ----------------------------------------------------------------------------------
  -- 115200 buad @ 100MHz
  constant cBuadCnt     : integer := 868;
  constant cHalfBuadCnt : integer := 434;

  -- 460800  buad @ 100MHz
  -- constant cBuadCnt : integer := 217;
  -- constant cHalfBuadCnt : integer := 108;
  ----------------------------------------------------------------------------------
  -- Signal declaration
  ----------------------------------------------------------------------------------
  -- state machine
  type SerStateType is (
      stIdle,    -- idle state
      stRxStart, -- start bit
      stWait -- wait for the stop bit
    );
  signal rState : SerStateType;

  -- data interface
  signal rSerDataIn  : std_logic;                    -- serial data input
  signal rRxFfWrData : std_logic_vector(8 downto 0); -- data 1 byte for FIFO

  -- control signal
  signal rRxFfWrEn : std_logic;                    -- data enable for the FIFO
  signal rDataCnt  : std_logic_vector(3 downto 0); -- data counter
  signal rBuadCnt  : std_logic_vector(9 downto 0); -- buad counter

begin
  ----------------------------------------------------------------------------------
  -- Output assignment
  ----------------------------------------------------------------------------------
  RxFfWrData <= rRxFfWrData(8 downto 1);
  RxFfWrEn   <= rRxFfWrEn;

  ----------------------------------------------------------------------------------
  -- DFF 
  ----------------------------------------------------------------------------------
  -- Only clocked on rising edge
  -- Reset is synchronous and active low
  -- Rx state machine

  u_rState: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rState <= stIdle;
      else
        case (rState) is
          when stIdle =>
            if (SerDataIn = '0') then
              rState <= stRxStart;
            else
              rState <= stIdle;
            end if;

          when stRxStart =>
            if (rDataCnt = 8 and rBuadCnt = 1) then
              if (SerDataIn = '0') then
                rState <= stWait;
              else
                rState <= stIdle;
              end if;
            else
              rState <= stRxStart;
            end if;

          when stWait =>
            if (SerDataIn = '1') then
              rState <= stIdle;
            else
              rState <= stWait;
            end if;
        end case;
      end if;
    end if;
  end process;

  -- Sync the serial data input

  u_rSerDataIn: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      rSerDataIn <= SerDataIn;
    end if;
  end process;

  -- data 1 byte for FIFO

  u_rRxFfWrData: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rRxFfWrData <= (others => '0');
      else
        if (rState = stRxStart and rBuadCnt = cHalfBuadCnt) then
          rRxFfWrData <= rSerDataIn & rRxFfWrData(8 downto 1);
        else
          rRxFfWrData <= rRxFfWrData;
        end if;
      end if;
    end if;
  end process;

  -- data enable for the FIFO

  u_rRxFfWrEn: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rRxFfWrEn <= '0';
      else
        if (rState = stRxStart and RxFfFull = '0' and rDataCnt = 8 and rBuadCnt = 1) then
          rRxFfWrEn <= '1';
        else
          rRxFfWrEn <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Data counter

  u_rDataCnt: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rDataCnt <= (others => '0');
      else
        if (rState = stRxStart and rBuadCnt = 1) then
          if (rDataCnt = 8) then
            rDataCnt <= (others => '0');
          else
            rDataCnt <= rDataCnt + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Buad counter

  u_rBuadCnt: process (Clk) is
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rBuadCnt <= conv_std_logic_vector(cBuadCnt, 10);
      else
        if (rBuadCnt = 1 or rState = stIdle) then
          rBuadCnt <= conv_std_logic_vector(cBuadCnt, 10);
        elsif (rState = stRxStart) then
          rBuadCnt <= rBuadCnt - 1;
        end if;
      end if;
    end if;
  end process;

end architecture;
