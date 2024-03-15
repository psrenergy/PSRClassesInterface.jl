using PSRClassesClassicInterface

PSRClassesClassicInterface.initialize()

const PSRCCI = PSRClassesClassicInterface
const PSRI   = PSRCCI.PSRClassesInterface

casepath = raw"C:\Users\pedroxavier\Desktop\Case33"

cmgbus_ = PSRI.file_to_array(
    PSRI.OpenBinary.Reader, 
    joinpath(casepath,"cmgbus"),
    use_header = false,
    # header = ["bus", "name", "base_kv", "vmax", "vmin", "va", "vm", "code"],
)


cmgbus_ = PSRI.file_to_array(PSRCCI.GrafReader{PSRIOGrafResultBinary}, 
    joinpath(casepath,"cmgbus"),
    use_header = false
)