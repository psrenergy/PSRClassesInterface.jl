# You should run the script from the profiling directory

using Profile
using PProf

file_name = "profile.pb.gz"

PProf.refresh(file=file_name, webport = 57998)
