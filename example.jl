import PSRClassesInterface
const PSRI = PSRClassesInterface

#Sets CSV file path
FILE_PATH = joinpath(".", "example")

#Creates Reader instance
ior = PSRI.OpenCSV.Reader

#Opens file
ior = PSRI.open(ocr, FILE_PATH)

#Creates data destination structure according to metadata stored in the Reader
n_rows = ior.stages*ior.scenarios*ior.blocks
data = zeros(Float64, (n_rows, ior.num_agents))

#Data reading loop
for row = 1:n_rows
    
    #Reads CSV row into data structure
    PSRI.next_registry(ior)
    data[row,:] = ior.data
end

#Closes file
PSRI.close(ior)

