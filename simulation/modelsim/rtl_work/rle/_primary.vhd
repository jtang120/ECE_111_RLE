library verilog;
use verilog.vl_types.all;
entity rle is
    port(
        clk             : in     vl_logic;
        nreset          : in     vl_logic;
        start           : in     vl_logic;
        message_addr    : in     vl_logic_vector(31 downto 0);
        message_size    : in     vl_logic_vector(31 downto 0);
        rle_addr        : in     vl_logic_vector(31 downto 0);
        rle_size        : out    vl_logic_vector(31 downto 0);
        done            : out    vl_logic;
        port_A_clk      : out    vl_logic;
        port_A_data_in  : out    vl_logic_vector(31 downto 0);
        port_A_data_out : in     vl_logic_vector(31 downto 0);
        port_A_addr     : out    vl_logic_vector(15 downto 0);
        port_A_we       : out    vl_logic
    );
end rle;
