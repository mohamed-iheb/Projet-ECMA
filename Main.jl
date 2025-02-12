#Main pour faire les tests de performances
using Plots
using Base.Threads
using Dates
include("Pb_Statique_V0.jl")
include("LazyCallback.jl")
include("Dualisation.jl")
include("heuristique.jl")


objectif_statique_n5 = 2561
objectif_robuste_n5 = 2786

objectif_statique_non_euclidien_euclidien = [[2554, 1857, 2335, 2699, 2190],[3022, 2983, 3574, 3529, 4835]]
objectif_robuste_non_euclidien_euclidien = [[3307, 2066, 3270, 3113, 2684],[3087, 3132, 3776, 4181, 5423]]


timeS=[]
timeD=[]
timeL=[]
valS=[]
valD=[]
valL=[]
P=[]
for E in ["false", "true"]
    k=0
    for i in ["6", "7", "8", "9", "10"]
        k=k+1
        if E == "true"
            PR= 100 * (objectif_robuste_non_euclidien_euclidien[2][k] - objectif_statique_non_euclidien_euclidien[2][k]) /  objectif_statique_non_euclidien_euclidien[2][k]
        else
            PR= 100 * (objectif_robuste_non_euclidien_euclidien[1][k] - objectif_statique_non_euclidien_euclidien[1][k]) /  objectif_statique_non_euclidien_euclidien[1][k]
        end
        println("___________________________________")
        include("data/n_"*i*"-euclidean_"*E)

        t1=Dates.now()
        v= Resolution_MTZ(n, d, t, C)
        t2=Dates.now()
        push!(timeS, t2 - t1) 

        t1=Dates.now()
        vD= Resolution_Dualisation(n,d,t,C,th,T)
        t2=Dates.now()
        push!(timeD, t2 - t1) 

        t1=Dates.now()
        vL= Resolution_LCb(n,d,t,C,th)
        t2=Dates.now()
        push!(timeL, t2 - t1) 

        push!(valD, vD)  
        push!(valL, vL)  
        push!(valS, v)  
        push!(P, PR) 
    end
end
println(valS)
println(valD)
println(valL)
println(timeS)
println(timeL)
println(timeD)
println(P)

# Conversion en secondes
timeS = [t.value / 1000 for t in timeS]  
timeD = [t.value / 1000 for t in timeD]
timeL = [t.value / 1000 for t in timeL]

println("timeS =",timeS)
println("timeL =",timeL)
println("timeD =",timeD)


GtimeS=[]
GtimeD=[]
GtimeL=[]

dir_path = "data/"
for file in readdir(dir_path)
    file_path = joinpath(dir_path, file)
    println("___________________________________________")
    include(file_path)

    # Résolution MTZ avec timeout de 1s
    t1 = Dates.now()
    task = @spawn Resolution_MTZ(n, d, t, C)
    try
        v = fetch(task, 1)  # Attend max 1s
    catch
        println("Timeout pour Resolution_MTZ")
    end
    t2 = Dates.now()
    push!(GtimeS, t2 - t1)

    # Résolution Dualisation avec timeout de 1s
    t1 = Dates.now()
    task = @spawn Resolution_Dualisation(n, d, t, C, th, T)
    try
        vD = fetch(task, 1)  # Attend max 1s
    catch
        println("Timeout pour Resolution_Dualisation")
    end
    t2 = Dates.now()
    push!(GtimeD, t2 - t1)

    # Résolution LCb avec timeout de 1s
    t1 = Dates.now()
    task = @spawn Resolution_LCb(n, d, t, C, th)
    try
        vL = fetch(task, 1)  # Attend max 1s
    catch
        println("Timeout pour Resolution_LCb")
    end
    t2 = Dates.now()
    push!(GtimeL, t2 - t1)
end


GtimeS = [t.value / 1000 for t in GtimeS]  
GtimeD = [t.value / 1000 for t in GtimeD]
GtimeL = [t.value / 1000 for t in GtimeL]

println("timeS =",GtimeS)
println("timeL =",GtimeL)
println("timeD =",GtimeD)