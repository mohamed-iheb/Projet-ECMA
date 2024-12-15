using JuMP
using CPLEX
using Dates
t1=Dates.now()
function Resolution_MTZ(n::Int64,d,t,C)
    
    m = Model(CPLEX.Optimizer)
    
    # Variable binaire x[i, j] : 1 si l'arc (i, j) est utilisé dans le chemin optimal, 0 sinon
    @variable(m, x[1:n, 1:n], Bin)
    @variable(m, u[1:n]>=0, Int) 
    @variable(m, q[1:n]>=0, Int) 

    # Conservation de flux
    @constraint(m, [i in 2:n],sum(x[i, j] for j in 1:n) == 1)
    @constraint(m, [i in 2:n],sum(x[j, i] for j in 1:n) == 1)
  

    
    #  élimination de cycles
    @constraint(m, [i in 1: n,j in 2: n ], u[i]+x[i,j]-2*n*(1-x[i,j]) <= u[j])
    
    # satisfaction de demande 
    @constraint(m, [i in 1: n], q[i] <= C)
    @constraint(m, [i in 1: n], q[i] >= d[i])
    #@constraint(m,  q[1] == C)

    M = 1000  # Constante suffisamment grande pour la linéarisation
    @constraint(m, [i in 2: n, j in 2 : n ; i != j ], q[j] >= q[i]- d[i] - M *(1-x[i,j]))
    @constraint(m, [i in 2: n, j in 2 : n ; i != j ], q[j] <= q[i]- d[i] + M *(1-x[i,j]))




    
    # Objectif : minimiser la distance totale
    @objective(m, Min, sum(t[i,j] * x[i, j] for i in 1:n for j in 1:n))
    
    # Résolution
    optimize!(m)
    

    # Récupérer les résultats
    vx = value.(x)
 
    status = termination_status(m)
    isOptimal = status == MOI.OPTIMAL
    println(vx)
    println("Solution optimale trouvée : ", isOptimal)
    println("la distance optimale trouvé :",objective_value(m))
 
    afficher(0,vx,1,n,1)
end
function afficher(s,vx,i,n,i_f)
    for j in 1:n
        if vx[i,j]==1 
            vx[i,j]=0
            s=s+1
            print(i," -> ")
            if j==1 print(1, "\n") end
            afficher(s,vx,j,n,1)
        end
    end
end

# Pour une donnée manuelle des instances :
n = 5
t = [
    0 260 864 263 374;
    260 0 796 59 114;
    864 796 0 855 797;
    263 59 855 0 130;
    374 114 797 130 0
]
T = 6
th = [6, 1, 2, 8, 1]
d = [0, 6, 2, 5, 3]
C = 12

# Optimisation
Resolution_MTZ(n, d, t, C)

# Temps de calcul
t2=Dates.now()
println("Temps de calcul= ",t2-t1)