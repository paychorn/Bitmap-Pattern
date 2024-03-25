library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity BitMapPatt Is 
Port (
  RstB        : in std_logic;
  Clk         : in std_logic;

  BmpFfWrData : out std_logic_vector( 23 downto 0 );
  BmpFfWrEn   : out std_logic;

	RxFfWrData	: in	std_logic_vector( 7 downto 0 );
	RxFfWrEn	  : in	std_logic
);
End Entity BitMapPatt;

Architecture RTL of BitMapPatt Is 

----------------------------------------------------------------------------------
-- Component declaration
----------------------------------------------------------------------------------
	
	
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
  -- State machine
  type BmpStateType is (
    stHeader,
    stBmpBody
  );
  signal  rState 		    : BmpStateType;

  -- Bitmap Data Interface
  signal rBmpFfWrData   : std_logic_vector( 23 downto 0 ); -- Bitmap write data

  -- Bitmap Control Interface
  signal rBmpFfWrEn     : std_logic;  -- Bitmap write enable for FIFO
  
  -- Internal Controllers
  signal rRgbWrCnt      : std_logic_vector( 1 downto 0 ); -- RGB controller (='1' : have done 3 bytes)
  signal rHeaderCnt     : std_logic_vector( 5 downto 0 ); -- Header address (54 bytes)
  signal rBodyCnt       : std_logic_vector( 19 downto 0 ); -- Body address (1024x768x3 bytes)

Begin 
----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------

  BmpFfWrEn   <= rBmpFfWrEn;
  BmpFfWrData <= rBmpFfWrData;

----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------

  -- state machine
  u_rState : Process (Clk) Is 
  Begin
    if( rising_edge(Clk) ) then
      if( RstB='0' ) then
        rState <= stHeader;
    else
      case( rState ) is
        when stHeader =>
          if( rHeaderCnt = 53 and RxFfWrEn = '1' ) then
            rState <= stBmpBody; -- start sending bitmap data
          else rState <= stHeader;
          end if;

        when stBmpBody =>
        if( rBodyCnt = 786431 and RxFfWrEn = '1' and rRgbWrCnt = 1 ) then
          rState <= stHeader; -- reset
        else rState <= stBmpBody;
        end if;
        end case;
      end if;
    end if;
  End Process u_rState;

  -- Bitmap write data for FIFO
  u_rRxFfWrData : Process (Clk) Is 
  Begin
    if ( rising_edge(Clk) ) then
      if ( RstB = '0' ) then
        rBmpFfWrData <= ( others => '1' );
      else
        if ( rState = stBmpBody and RxFfWrEn = '1' ) then
          rBmpFfWrData <= RxFfWrData & rBmpFfWrData( 23 downto 8 );
        end if;
      end if;
    end if;
  End Process u_rRxFfWrData;

  -- Bitmap write enable for FIFO
  u_rBmpFfWrEn : Process (Clk) Is
  Begin
    if ( rising_edge(Clk) ) then
      if ( RstB = '0' ) then
        rBmpFfWrEn <= '0';
      else
        if ( rState = stBmpBody and RxFfWrEn='1' and rRgbWrCnt = 1 ) then
          rBmpFfWrEn <= '1';
        else
          rBmpFfWrEn <= '0';
        end if;
      end if;
    end if;
  End Process u_rBmpFfWrEn;

  -- RGB controller
  u_rRgbWrCnt : Process (Clk) Is 
  Begin
    if ( rising_edge(Clk) ) then
      if ( RstB = '0' ) then
        rRgbWrCnt  <= "11";
      else
        if( rState = stBmpBody and RxFfWrEn = '1' ) then
          if ( rRgbWrCnt = 1 ) then
            rRgbWrCnt  <= "11";
          else 
            rRgbWrCnt  <= rRgbWrCnt - 1;
          end if;
        else
          rRgbWrCnt  <= rRgbWrCnt ;
        end if;
      end if;
    end if;
  End Process u_rRgbWrCnt ;

  -- Header address counter for 54 bytes
  u_rHeaderCnt : Process (Clk) Is 
  Begin
    if ( rising_edge(Clk) ) then
      if ( RstB = '0' ) then
        rHeaderCnt  <= ( others => '0' );
      else
        if( rState = stHeader and RxFfWrEn = '1' ) then
          if( rHeaderCnt = 53 ) then
            rHeaderCnt  <= ( others => '0' );
          else
            rHeaderCnt  <= rHeaderCnt + 1;
          end if;
        else
        rHeaderCnt  <= rHeaderCnt ;
        end if;
      end if;
    end if;
  End Process u_rHeaderCnt;

  -- Body address counter for 1024x768x3 bytes
  u_rBodyCnt  : Process (Clk) Is 
  Begin
    if ( rising_edge(Clk) ) then
      if ( RstB='0' ) then
        rBodyCnt   <= ( others => '0' );
      else
        if( rState = stBmpBody and RxFfWrEn = '1' and rRgbWrCnt = 1 ) then
          -- (1024 x 768)
          if( rBodyCnt = 786431 ) then
            rBodyCnt   <= (others => '0');
          else
            rBodyCnt   <= rBodyCnt+ 1;
          end if;
        else
          rBodyCnt   <= rBodyCnt;
        end if;
      end if;
    end if;
  End Process u_rBodyCnt ;

End Architecture RTL;