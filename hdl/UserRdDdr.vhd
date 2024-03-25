----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     UserRdDdr.vhd
-- Title        Top
--
-- Company      Design Gateway Co., Ltd.
-- Project      DDCamp
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      1.00
-- Author       B.Attapon
-- Date         2017/12/20
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity UserRdDdr Is
	Port
	(
		RstB					: in	std_logic;							-- use push button Key0 (active low)
		Clk						: in	std_logic;							-- clock input 100 MHz

		DipSwitch			: in 	std_logic_vector( 1 downto 0 );
		
		-- HDMICtrl I/F
		HDMIReq				: out	std_logic;
		HDMIBusy			: in	std_logic;
		
		-- RdCtrl I/F
		MemInitDone		: in	std_logic;
		MtDdrRdReq		: out	std_logic;
		MtDdrRdBusy		: in	std_logic;
		MtDdrRdAddr		: out	std_logic_vector( 28 downto 7 );
		
		-- D2URdFf I/F
		D2URdFfWrEn		: in	std_logic;
		D2URdFfWrData	: in	std_logic_vector( 63 downto 0 );
		D2URdFfWrCnt	: out	std_logic_vector( 15 downto 0 );
		
		-- URd2HFf I/F
		URd2HFfWrEn		: out	std_logic;
		URd2HFfWrData	: out	std_logic_vector( 63 downto 0 );
		URd2HFfWrCnt	: in	std_logic_vector( 15 downto 0 )
	);
End Entity UserRdDdr;

Architecture RTL Of UserRdDdr Is

----------------------------------------------------------------------------------
-- Component declaration
----------------------------------------------------------------------------------
	
	
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	-- HDMICtrl I/F
	signal	rHDMIReq			: std_logic;

	-- RdCtrl I/F
	signal rMemInitDone	: std_logic_vector( 1 downto 0 );
	signal rMtDdrRdReq 		: std_logic_vector( 1 downto 0 ); 
	signal rMtDdrRdAddr	  : std_logic_vector( 28 downto 7 );
	
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------

	-- HDMICtrl I/F
	HDMIReq			<= rHDMIReq;

	-- RdCtrl I/F
	MtDdrRdReq  <= rMtDdrRdReq(0);
	MtDdrRdAddr <= rMtDdrRdAddr;

	-- Bypass the data
	D2URdFfWrCnt <= URd2HFfWrCnt;
	URd2HFfWrEn <= D2URdFfWrEn;
	URd2HFfWrData <= D2URdFfWrData;

----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------
	
	-- HDMICtrl I/F
	u_rMemInitDone : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMemInitDone	<= "00";
			else
				-- Use rMemInitDone(1) in your design
				rMemInitDone	<= rMemInitDone(0) & MemInitDone;
			end if;
		end if;
	End Process u_rMemInitDone;

	u_rHDMIReq : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rHDMIReq	<= '0';
			else
				if ( HDMIBusy='0' and rMemInitDone(1)='1' ) then
					rHDMIReq	<= '1';
				elsif ( HDMIBusy='1' )  then
					rHDMIReq	<= '0';
				else
					rHDMIReq	<= rHDMIReq;
				end if;
			end if;
		end if;
	End Process u_rHDMIReq;

	--------------------------------------------------
	-- RdCtrl I/F
	u_rMtDdrRdReq : Process (Clk) is
		begin
			if ( rising_edge(Clk) ) then
				if ( RstB='0' ) then
					rMtDdrRdReq <= "11";
				else
					if ( MtDdrRdBusy = '0' ) then
						rMtDdrRdReq <= rMtDdrRdReq(0) & '1';
					else 
						rMtDdrRdReq <= rMtDdrRdReq(0) & '0';
					end if;
				end if;
			end if;
		end Process u_rMtDdrRdReq;

	u_rMtDdrRdAddr : Process (Clk) is
	begin
		if ( rising_edge(Clk) ) then
			if ( RstB = '0' ) then
				rMtDdrRdAddr(28 downto 27) <= DipSwitch;
				rMtDdrRdAddr(26 downto  7) <= (others => '0');
			else
				if ( rMtDdrRdReq = "10" ) then
					-- If the end of image, read at 0th pixel
					-- end image : (1024x768x4) / 128
					if ( rMtDdrRdAddr(26 downto 7) = 24575 ) then
						rMtDdrRdAddr(28 downto 27) <= DipSwitch;
						rMtDdrRdAddr(26 downto  7) <= (others => '0');
					else
						rMtDdrRdAddr(26 downto 7)  <= rMtDdrRdAddr(26 downto 7) + 1;
					end if;
				else
						rMtDdrRdAddr(28 downto 7) <= rMtDdrRdAddr(28 downto 7);
					end if;
				end if;
			end if;
	end Process u_rMtDdrRdAddr;

End Architecture RTL;