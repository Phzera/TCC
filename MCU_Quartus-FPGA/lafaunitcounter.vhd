-- Pulse Counter 

--top level entity
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY lafaunitcounter IS
PORT
(
-- o transmitter to RS-232 port where data are sent to Matlab
		UART_TXD	:OUT	STD_LOGIC;
-- The 50 MHz clock that is provided on the DE2 Board
		Clock_50	:IN	STD_LOGIC;
			
-- The switchs 0 through 17 on the DE2 Board	
		SW		:IN	STD_LOGIC_VECTOR(17 DOWNTO 0);
		
-- The input pins on 40 pin expansion header GPIO pins
-- (which can be used for input or output signals).
-- Note that the pins on the expansion header do not match the pin assignments used by
--  Quartus II when programming the DE2-115 Board		
	GPIO_3, GPIO_7, GPIO_11, GPIO_15,GPIO_21, GPIO_25, GPIO_29, GPIO_33 	:IN		STD_LOGIC ;
		
--The respective GND for each channel		
	GPIO_4, GPIO_8, GPIO_12, GPIO_16,GPIO_22,GPIO_24,GPIO_30,GPIO_34 : OUT  STD_LOGIC;
	
-- The output test signal pins on the 14 pin general purpose header
-- (which can be used for input or output signals).
-- Note that the pins on the expansion header do not match the pin assignments used by
--  Quartus II when programming the DE2 Board		
-- The red LED lights 0 through 17 on the DE2-115 Board
		LEDR		:OUT	STD_LOGIC_VECTOR(17 DOWNTO 0)
	);

END lafaunitcounter;


ARCHITECTURE Behavior OF lafaunitcounter IS
--This COMPONENT is the Megafunction "lpm_counter" using a 14 bit output and an asynchronous clear
	
	COMPONENT data_trigger_counter
		PORT
		(
			aclr	: IN 	STD_LOGIC;
			clock	: IN 	STD_LOGIC;
			q	: OUT 	STD_LOGIC_VECTOR (14 DOWNTO 0)
		);
	END COMPONENT;	
	
-- This COMPONENT is the Megafunction "lpm_counter" using a 13 bit output and an asynchronous clear
	COMPONENT baud_counter
		PORT
		(
			aclr	: IN 	STD_LOGIC;
			clock	: IN 	STD_LOGIC;
			q	: OUT 	STD_LOGIC_VECTOR (14 DOWNTO 0)
		);
	END COMPONENT;	
	
-- This COMPONENT is the Megafunction "lpm_counter" using a 32 bit output and an asynchronous clear
	COMPONENT counter
		PORT
		(
			aclr	: IN	STD_LOGIC;
			clock	: IN	STD_LOGIC;
			q	: OUT	STD_LOGIC_VECTOR (31 DOWNTO 0)
		);
	END COMPONENT;
	
-- This COMPONENT takes in the single photon counts and sends it out
-- on the RS232 port, the data stream is started by data_trigger every 1/10th of a second
-- and the rate of the data_stream is controled by the 19200 bits/sec baud clock
	COMPONENT DataOut
		PORT
		(
			A	:IN		STD_LOGIC_VECTOR(31 DOWNTO 0);
			B	:IN		STD_LOGIC_VECTOR(31 DOWNTO 0);
			C	:IN		STD_LOGIC_VECTOR(31 DOWNTO 0);
			D	:IN		STD_LOGIC_VECTOR(31 DOWNTO 0);
			E 	:IN		STD_LOGIC_VECTOR(31 DOWNTO 0);
			F	:IN		STD_LOGIC_VECTOR(31 DOWNTO 0);
			G	:IN		STD_LOGIC_VECTOR(31 DOWNTO 0);
			H	:IN		STD_LOGIC_VECTOR(31 DOWNTO 0);
			
			clk		:IN		STD_LOGIC;
			data_trigger	:IN		STD_LOGIC;
			UART_TXD	:OUT		STD_LOGIC
		);
	END COMPONENT;
	
	
-- This component takes in the 50 MHz clock and turns it in a 200MHz clocl	
	COMPONENT pll
		PORT (
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		
		);
	END COMPONENT;
	
			
-- This SIGNAL counts the baud clock until it reaches 1920, which occurs every 1/10th of a second
	SIGNAL data_trigger_count: STD_LOGIC_VECTOR(14 DOWNTO 0);
-- This SIGNAL is turned on every 1/10th of a second for one 50 MHz clock pulse and resets
-- the photon detection counters
	SIGNAL data_trigger_reset: STD_LOGIC;
-- This SIGNAL is turned on every 1/10th of a second and begins the data stream out
	SIGNAL data_trigger: STD_LOGIC;
-- This SIGNAL acts as a clock to output data at the baud rate of 19200 bits/second
	SIGNAL baud_rate_clk: STD_LOGIC;
-- This SIGNAL counts the 50 MHz clock pulses until it reaches 2604 in order to time the baud clock
	SIGNAL baud_rate_count: STD_LOGIC_VECTOR(14 DOWNTO 0);
-- These SIGNALs represent the four input pulse from the photon detectors		
	SIGNAL A, B, C, D, E, F, G, H: STD_LOGIC;		
	
		
-- This SIGNAL represents the top level design entity instantiation of the number of counts
-- in the detectors A, B, C, D, E, F, G, and H respectively
	SIGNAL A_top, B_top, C_top, D_top, E_top, F_top, G_top, H_top: STD_LOGIC_VECTOR(31 DOWNTO 0);
	
-- This SIGNAL represents the number of counts in the detectors A, B, C, and D respectively
	SIGNAL A_out, B_out, C_out, D_out, E_out, F_out, G_out,H_out: STD_LOGIC_VECTOR(31 DOWNTO 0);
-- This SIGNAL is the only variable that is sent to the computer from the program	
	SIGNAL Output: STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	SIGNAL Clock_200: STD_LOGIC;
	
	BEGIN
-- This initializes the input PMTs signals when the respective switches is ON
-- Note that for this current circuit design, you might check if the data read is correct. Use SW(15)-sw(8)
-- to send fixed values through
	
	
	WITH SW(7) SELECT
		A <= GPIO_3	 WHEN '1',
			'0' 	 WHEN '0';
			
	WITH SW(6) SELECT
		B <= GPIO_7 	 WHEN '1',
			'0' 	 WHEN '0';
			
	WITH SW(5) SELECT
		C <= GPIO_11 	WHEN '1',
			'0' 	WHEN '0';
			
	WITH SW(4) SELECT
		D <= GPIO_15 	WHEN '1',
			'0' 	WHEN '0';
			
	WITH SW(3) SELECT
		E <= GPIO_21 	WHEN '1',
			'0' 	WHEN '0';
			
	WITH SW(2) SELECT
		F <= GPIO_25 	WHEN '1',
			'0' 	WHEN '0';
			
	WITH SW(1) SELECT
		G <= GPIO_29 	WHEN '1',
			'0' 	WHEN '0';
			
	WITH SW(0) SELECT
		H <= GPIO_33 	WHEN '1',
			'0' 	WHEN '0';							

	--envia valores fixos conhecidos aos sinais de contagem

	-- envia GND para os pinos adjacentes aos sinais
GPIO_4   <= '0'; 
GPIO_8   <= '0'; 
GPIO_12  <= '0';
GPIO_16  <= '0'; 
GPIO_22  <= '0'; 
GPIO_24  <= '0'; 
GPIO_30  <= '0'; 
GPIO_34  <= '0'; 
	
	-------------- TODO

-- Once the output of the 14 bit counter reaches 1920, this process turns on the SIGNAL 'data_trigger'
-- The SIGNAL 'data_trigger' then acts as a clock pulse, reseting the counts and changing the display
	PROCESS ( data_trigger_count )
		BEGIN
	IF data_trigger_count = "000011110000000" THEN -- 1920 => gate = 1/10 sec
																  -- 19200 => gate= 1 sec
			data_trigger_reset <= '1';
			data_trigger <= '1';
		ELSIF data_trigger_count = "000000000000000" THEN
			data_trigger_reset <= '0';
			data_trigger <= '1';
		ELSIF data_trigger_count = "000000000000001" THEN
			data_trigger_reset <= '0';
			data_trigger <= '1';
		ELSE
			data_trigger_reset <= '0';
			data_trigger <= '0';
		END IF;
	END PROCESS;
	
-- Once the output of the 13 bit counter reaches 2,604, this process turns on the SIGNAL 'baud_rate_clk'
-- The SIGNAL 'baud_rate_clk' then acts as a clock pulse, send the data out at the specified baud rate
	PROCESS ( baud_rate_count )
		BEGIN
--		IF baud_rate_count = "000101000101100" THEN --Clock_50
		IF baud_rate_count = "010100010110000" THEN --Clock_200
			baud_rate_clk <= '1';
		ELSE
			baud_rate_clk <= '0';
		END IF;
	END PROCESS;
	
	
	CLK: pll PORT MAP (Clock_50, Clock_200);

-- Uses the 14 bit counter and ~9,600 baud rate clock to count to 1/10th of a second to trigger DataOut
	C0: data_trigger_counter PORT MAP ( data_trigger_reset, baud_rate_clk, data_trigger_count );

-- Uses the 13 bit counter and 50 MHz clock to count the baud rate
--	C1: baud_counter PORT MAP ( baud_rate_clk, Clock_50, baud_rate_count );
	C1: baud_counter PORT MAP ( baud_rate_clk, Clock_200, baud_rate_count );
	
	CA: counter PORT MAP ( data_trigger_reset, A, A_top );
	CB: counter PORT MAP ( data_trigger_reset, B, B_top );
	CC: counter PORT MAP ( data_trigger_reset, C, C_top );
	CD: counter PORT MAP ( data_trigger_reset, D, D_top );
	CE: counter PORT MAP ( data_trigger_reset, E, E_top );
	CF: counter PORT MAP ( data_trigger_reset, F, F_top );
	CG: counter PORT MAP ( data_trigger_reset, G, G_top );
	CH: counter PORT MAP ( data_trigger_reset, H, H_top );
	
--	    counter(aclr : IN, clock : IN, q : OUT);
	
-- This process sets the single photon and coincidence photon count output arrays every 1/10th of a second
	PROCESS( data_trigger_reset )
	BEGIN
		IF data_trigger_reset'EVENT AND data_trigger_reset = '1' THEN
			A_out <= A_top;
			B_out <= B_top;
			C_out <= C_top;
			D_out <= D_top;
			E_out <= E_top;
			F_out <= F_top;
			G_out <= G_top;
			H_out <= H_top;
		END IF;	
	END PROCESS;
		

-- Sends the A, B, C, D, E, F, G e Hout on the RS-232 port
	D0: DataOut PORT MAP(A_out, B_out, C_out, D_out, E_out, F_out, G_out, H_out, baud_rate_clk, data_trigger, UART_TXD);

-- Turns on the corresponding red LED whenever one of the DE2 board switches is turned on
	LEDR <= SW;
	
END Behavior;
