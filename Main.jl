#Main pour faire les tests de performances
using Plots
using Base.Threads
using Dates
include("Pb_Statique_V0.jl")
include("LazyCallback.jl")
include("Dualisation.jl")
include("heuristique.jl")
include("PlansCoupants.jl")


objectif_statique_n5 = 2561
objectif_robuste_n5 = 2786

objectif_statique_non_euclidien_euclidien = [[2554, 1857, 2335, 2699, 2190],[3022, 2983, 3574, 3529, 4835]]
objectif_robuste_non_euclidien_euclidien = [[3307, 2066, 3270, 3113, 2684],[3087, 3132, 3776, 4181, 5423]]


timeS=[]
timeD=[]
timeL=[]
timeP=[]
timeH=[]
valH=[]
valP=[]
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
        vH= heuristique(n,d,t,C,th,T)
        t2=Dates.now()
        push!(timeH, t2 - t1) 

        t1=Dates.now()
        vP= PlC(n,d,t,C,th,T)
        t2=Dates.now()
        push!(timeP, t2 - t1) 

        t1=Dates.now()
        vL= Resolution_LCb(n,d,t,C,th)
        t2=Dates.now()
        push!(timeL, t2 - t1) 

        push!(valD, vD)  
        push!(valL, vL)  
        push!(valS, v)
        push!(valP, vP)  
        push!(valH, vH)  
        push!(P, PR) 
    end
end
println("valS  :",valS)
println("valD  :",valD)
println("valL  :",valL)
println("valH  :",valH)
println("valP  :",valP)
println(P)
#GH= (valH - objectif_robuste_non_euclidien_euclidien) 
println("GH =", 100*(valH -[3307, 2066, 3270, 3113, 2684,3087, 3132, 3776, 4181, 5423])/[3307, 2066, 3270, 3113, 2684,3087, 3132, 3776, 4181, 5423])
println("G00H =", objectif_robuste_non_euclidien_euclidien)
# Conversion en secondes
timeS = [t.value / 1000 for t in timeS]  
timeD = [t.value / 1000 for t in timeD]
timeL = [t.value / 1000 for t in timeL]
timeP = [t.value / 1000 for t in timeP]
timeH = [t.value / 1000 for t in timeH]

println("timeS =",timeS)
println("timeL =",timeL)
println("timeD =",timeD)
println("timeP =",timeP)
println("timeH =",timeH)

GtimeS=[]
GtimeD=[]
GtimeL=[]
GtimeP=[]
GtimeH=[]


dir_path = "data1/"
for file in readdir(dir_path)
    file_path = joinpath(dir_path, file)
    println("___________________________________________")
    include(file_path)

    t1=Dates.now()
    v= Resolution_MTZ(n, d, t, C)
    t2=Dates.now()
    push!(GtimeS, t2 - t1) 

    t1=Dates.now()
    vD= Resolution_Dualisation(n,d,t,C,th,T)
    t2=Dates.now()
    push!(GtimeD, t2 - t1)
    
    t1=Dates.now()
    vH= heuristique(n,d,t,C,th,T)
    t2=Dates.now()
    push!(GtimeH, t2 - t1) 

    t1=Dates.now()
    vP= PlC(n,d,t,C,th,T)
    t2=Dates.now()
    push!(GtimeP, t2 - t1) 

    t1=Dates.now()
    vL= Resolution_LCb(n,d,t,C,th)
    t2=Dates.now()
    push!(GtimeL, t2 - t1) 

end


GtimeS = [t.value / 1000 for t in GtimeS]  
GtimeD = [t.value / 1000 for t in GtimeD]
GtimeL = [t.value / 1000 for t in GtimeL]
GtimeP = [t.value / 1000 for t in GtimeP]
GtimeH = [t.value / 1000 for t in GtimeH]

println("timeS =",GtimeS)
println("timeL =",GtimeL)
println("timeD =",GtimeD)
println("timeP =",GtimeP)
println("timeH =",GtimeH)