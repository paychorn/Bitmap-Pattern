library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.STD_LOGIC_ARITH.all;
	use IEEE.STD_LOGIC_UNSIGNED.all;

entity UserRdDdr is
	port (
		RstB          : in  std_logic; -- use push button Key0 ( active low )
		Clk           : in  std_logic; -- clock input 100 MHz

		DipSwitch     : in  std_logic_vector(1 downto 0);

		-- HDMICtrl I/F
		HDMIReq       : out std_logic;
		HDMIBusy      : in  std_logic;

		-- RdCtrl I/F
		MemInitDone   : in  std_logic;
		MtDdrRdReq    : out std_logic;
		MtDdrRdBusy   : in  std_logic;
		MtDdrRdAddr   : out std_logic_vector(28 downto 7);

		-- D2URdFf Data I/F
		D2URdFfWrData : in  std_logic_vector(63 downto 0);

		-- D2URdFf Control I/F
		D2URdFfWrEn   : in  std_logic;
		D2URdFfWrCnt  : out std_logic_vector(15 downto 0);

		-- URd2HFf Data I/F
		URd2HFfWrData : out std_logic_vector(63 downto 0);

		-- URd2HFf Control I/F
		URd2HFfWrEn   : out std_logic;
		URd2HFfWrCnt  : in  std_logic_vector(15 downto 0)
	);
end entity;

architecture RTL of UserRdDdr is

	----------------------------------------------------------------------------------
	-- Component declaration
	----------------------------------------------------------------------------------
	----------------------------------------------------------------------------------
	-- Signal declaration
	----------------------------------------------------------------------------------
	-- HDMICtrl Interface
	signal rHDMIReq : std_logic; -- HDMI request to read data from DDR

	-- RdCtrl Interface
	signal rMemInitDone : std_logic_vector(1 downto 0);  -- The memory initialization is complete
	signal rMtDdrRdReq  : std_logic_vector(1 downto 0);  -- User request to read data from DDR
	signal rMtDdrRdAddr : std_logic_vector(28 downto 7); -- Start address to read data from DDR

begin

	----------------------------------------------------------------------------------
	-- Output assignment
	----------------------------------------------------------------------------------
	-- HDMICtrl I/F
	HDMIReq <= rHDMIReq;

	-- RdCtrl I/F
	MtDdrRdReq  <= rMtDdrRdReq(0);
	MtDdrRdAddr <= rMtDdrRdAddr;

	-- Bypass the data
	D2URdFfWrCnt  <= URd2HFfWrCnt;
	URd2HFfWrEn   <= D2URdFfWrEn;
	URd2HFfWrData <= D2URdFfWrData;

	----------------------------------------------------------------------------------
	-- DFF 
	----------------------------------------------------------------------------------
	-- [[ HDMICtrl I/F ]] -----------------------------
	-- Ensure memory initialized and HDMI ready.

	u_rHDMIReq: process (Clk) is
	begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rHDMIReq <= '0';
			else
				if ( HDMIBusy='0' and rMemInitDone(1)='1' ) then
					rHDMIReq <= '1';
				elsif ( HDMIBusy='1' ) then
					rHDMIReq <= '0';
				else
					rHDMIReq <= rHDMIReq;
				end if;
			end if;
		end if;
	end process;

	--[[ RdCtrl I/F ]] -----------------------------
	-- Sync the memory initialization done signal

	u_rMemInitDone: process (Clk) is
	begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMemInitDone <= "00";
			else
				-- Use rMemInitDone( 1 ) in your design
				rMemInitDone <= rMemInitDone(0) & MemInitDone;
			end if;
		end if;
	end process;

	-- Synchornize the request and maintain last input

	u_rMtDdrRdReq: process (Clk) is
	begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtDdrRdReq <= "11";
			else
				if ( MtDdrRdBusy='0' ) then
					rMtDdrRdReq <= rMtDdrRdReq(0) & '1';
				else
					rMtDdrRdReq <= rMtDdrRdReq(0) & '0';
				end if;
			end if;
		end if;
	end process;

	-- Calculate the address from the dip switch

	u_rMtDdrRdAddr: process (Clk) is
	begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtDdrRdAddr(28 downto 27) <= DipSwitch;
				rMtDdrRdAddr(26 downto 7) <= (others => '0');
			else
				if ( rMtDdrRdReq="10" ) then
					-- If the end of image, read at 0th pixel
					-- end image : ( 1024x768x4 ) / 128
					if ( rMtDdrRdAddr(26 downto 7)=24575 ) then
						rMtDdrRdAddr(28 downto 27) <= DipSwitch;
						rMtDdrRdAddr(26 downto 7) <= (others => '0');
					else
						rMtDdrRdAddr(26 downto 7) <= rMtDdrRdAddr(26 downto 7) + 1;
					end if;
				else
					rMtDdrRdAddr(28 downto 7) <= rMtDdrRdAddr(28 downto 7);
				end if;
			end if;
		end if;
	end process;

end architecture;
