module DoublePendulum
using GLMakie
const g=9.81
const E1=2.0e11
const E2=2.0e11
const A=0.00000314
m1=Observable(1.0)
m2=Observable(1.0)
l1=Observable(1.0)
l2=Observable(1.0)
l1_new=Observable(l1[])
l2_new=Observable(l2[])
O1=Observable(0.0)
w1=Observable(0.0)
O2=Observable(0.0)
w2=Observable(0.0)
Fxmass=Observable(0.0)
Fymass=Observable(0.0)
Fxmass1=Observable(0.0)
Fymass1=Observable(0.0)
Fxmass2=Observable(0.0)
Fymass2=Observable(0.0)
line1=Observable([(0.0, 0.0), (0.0, -l1_new[])])
line2=Observable([(0.0, -l1_new[]), (0.0, -l1_new[] - l2_new[])])
mass1=Observable((0.0, -l1_new[]))
mass2=Observable((0.0, -l1_new[] - l2_new[]))
global submit_button_clicked=false
reset_clicked=Observable(false)
const dt=0.002

function main()
    # Tworzenie okna
    fig=Figure(size=(1200, 800), autoresize=true)
    # Dzielenie figury na 2 części
    axis=Axis(fig[1, 1], title="Symulacja podwójnego wahadła", xlabel="X[m]", ylabel="Y[m]", aspect=DataAspect(),tellwidth=false, tellheight=false)  
    right_panel=fig[1, 2] = GridLayout(tellwidth=false, tellheight=false)

    #Wyłączenie możliwości przybliżania wykresu poprzez przycisk myszy
    Makie.deactivate_interaction!(axis, :rectanglezoom)

    #Tworzenie textboxów sliderów do wartości początkowych i parametrów
    textbox_fx=Textbox(right_panel[1, 1], placeholder = "0.0", tellwidth = false)
    textbox_fy=Textbox(right_panel[2, 1], placeholder = "0.0", tellwidth = false)
    submit_button=Button(right_panel[3, 1:2], label="SUBMIT", width=100, tellwidth=false)
    slider_m1=Slider(right_panel[4, 1], range=0.1:0.1:5.0, startvalue=1.0)
    slider_m2=Slider(right_panel[5, 1], range=0.1:0.1:5.0, startvalue=1.0)
    slider_l1=Slider(right_panel[6, 1], range=0.1:0.1:5.0, startvalue=1.0)
    slider_l2=Slider(right_panel[7, 1], range=0.1:0.1:5.0, startvalue=1.0)
    slider_O1=Slider(right_panel[8,1], range=-5*π/12:π/12:5*π/12, startvalue=0.0)
    slider_w1=Slider(right_panel[9,1], range=-10.0:0.5:10.0, startvalue=0.0)
    slider_O2=Slider(right_panel[10,1], range=-5*π/12:π/12:5*π/12, startvalue=0.0)
    slider_w2=Slider(right_panel[11,1], range=-10.0:0.5:10.0, startvalue=0.0)

    # Dodanie labeli do sliderów i textboxów
    lbfx=Label(right_panel[1, 2], "Wartość Fx")
    lbfy=Label(right_panel[2, 2], "Wartość Fy")
    lb1=Label(right_panel[4, 2], "Masa 1: 1.0 kg")
    lb2=Label(right_panel[5, 2], "Masa 2: 1.0 kg")
    lb3=Label(right_panel[6, 2], "Długość 1: 1.0 m")
    lb4=Label(right_panel[7, 2], "Długość 2: 1.0 m")
    lb5=Label(right_panel[8, 2], "Kąt 1: 0.0 rad")
    lb6=Label(right_panel[9, 2], "Prędkość 1: 0.0 rad/s")
    lb7=Label(right_panel[10, 2], "Kąt 2: 0.0 rad")
    lb8=Label(right_panel[11, 2], "Prędkość 2: 0.0 rad/s")

    # Łączenie observable z sliderami
    connect!(m1, slider_m1.value)
    connect!(m2, slider_m2.value)
    connect!(l1, slider_l1.value)
    connect!(l2, slider_l2.value)
    connect!(O1, slider_O1.value)
    connect!(w1,slider_w1.value)
    connect!(O2, slider_O2.value)
    connect!(w2,slider_w2.value)

    # Funkcje on dla każdego slidera do wyświetlania obecnej wartości
    on(slider_m1.value) do val
        lb1.text = "Masa 1:$(round(val, digits=1)) kg"
    end

    on(slider_m2.value) do val
        lb2.text = "Masa 2:$(round(val, digits=1)) kg"
    end

    on(slider_l1.value) do val
        lb3.text = "Długość 1:$(round(val, digits=1)) m"
    end

    on(slider_l2.value) do val
        lb4.text = "Długość 2:$(round(val, digits=1)) m"
    end
    on(slider_O1.value) do val
        lb5.text = "Kąt 1:$(round(val, digits=3)) rad"
    end
    on(slider_w1.value) do val
        lb6.text = "Predkość 1:$(round(val, digits=1)) rad/s"
    end
    on(slider_O2.value) do val
        lb7.text = "Kąt 2:$(round(val, digits=3)) rad"
    end
    on(slider_w2.value) do val
        lb8.text = "Predkość 2:$(round(val, digits=1)) rad/s"
    end

    # Tworzenie przycisków
    start_button=Button(right_panel[12, 1:2], label="RUN", width=200, tellwidth=false)
    reset_button=Button(right_panel[13, 1:2], label="RESET", width=200, tellwidth=false)
    is_running=Observable(false)

    # Rysowanie podwójnego wahadła
    lines!(axis, line1; color=:black)
    lines!(axis, line2; color=:black)
    scatter!(axis, mass1; color=:blue, markersize=15)
    scatter!(axis, mass2; color=:red, markersize=15)

    # Równania różniczkowe podwójnego wahadła
    function double_pendulum!(state)
        θ1,ω1,θ2,ω2=state
        Δθ=θ1-θ2
        fi=(1.0+(m1[]+m2[]))  
        #Obliczenie sił naprężeń prętów
        F_line1=(m1[]*g*cos(θ1))+(m1[]*l1[]*ω1^2)+(m2[]*g*cos(θ1))+(m2[]*l2[]*ω2^2)
        F_line2=(m2[]*g*cos(θ2))+(m2[]*l2[]*ω2^2)
        # Zmiana długości odkształconych prętów
        l1_new[]=l1[]+(F_line1*l1[])/(A*E1)
        l2_new[]=l2[]+(F_line2*l1[])/(A*E2)
        #Równania różniczkowe ruchu (prędkość i przyspieszenie)
        diff_state=zeros(4)
        diff_state[1]=ω1
        diff_state[2]=(g*(sin(θ2)*cos(Δθ)-fi*sin(θ1))-(l2_new[]*ω2^2+l1_new[]*ω1^2*cos(Δθ))*sin(Δθ))/(l1_new[]*(fi-cos(Δθ)^2))
        diff_state[3]=ω2
        diff_state[4]=(g*fi*(sin(θ1)*cos(Δθ)-sin(θ2))+sin(Δθ)*(fi*l1_new[]*ω1^2+l2_new[]*ω2^2*cos(Δθ)))/(l2_new[]*(fi-cos(Δθ)^2))
        return diff_state
    end

    #Runge-Kutta czwartego rzędu do wyliczania równań
    function runge_kutta(state, dt)
        k1=double_pendulum!(state)
        k2=double_pendulum!(state+0.5*dt*k1)
        k3=double_pendulum!(state+0.5*dt*k2)
        k4=double_pendulum!(state+dt*k3)
        new_state=state+(dt/6)*(k1+2*k2+2*k3+k4)
        return new_state
    end

    #Obliczenia dla jednego stepu symulacji i odbicia
    function step!(state, dt)
        new_state=runge_kutta(state, dt)
        θ1, ω1, θ2, ω2=new_state
        #Nowe pozycje kulek po obliczeniach
        x1=l1_new[]*sin(θ1)
        y1=-l1_new[]*cos(θ1)
        x2=x1+l2_new[]*sin(θ2)
        y2=y1-l2_new[]*cos(θ2)
        #Odbicia dla mass1
        if y1>=0
            y1=0 
            ω1=-ω1*0.95
            θ1=asin(x1/l1_new[])
            #aktualizacja pozycji po odbiciu
            x2=x1+l2_new[]*sin(θ2)
            y2=y1-l2_new[]*cos(θ2)
        end

        #odbicia dla mass2
        if y2>=0
            y2=0
            #Warunek dla odbicia mass2 jeżeli kulki poruszają się w te samą stronę
            if ω1*ω2>0
                ω1=-ω1 *0.95
            end
            ω2=-ω2*0.95
            if x2>x1
                θ2=acos((y1-y2) /l2_new[])
            else
                θ2=-acos((y1-y2)/l2_new[])
            end
        end
        y1=-l1_new[]*cos(θ1)
        x2=x1+l2_new[]*sin(θ2)
        y2=y1-l2_new[]*cos(θ2)
        return [θ1, ω1, θ2, ω2], x1, y1, x2, y2
    end

    #aktualizacja pozycji wahadła
    function update!(x1, y1, x2, y2)
        line1[]=[(0.0, 0.0), (x1, y1)]
        line2[]=[(x1, y1), (x2, y2)]
        mass1[]=(x1, y1)
        mass2[]=(x2, y2)
    end

    function simulation()
        println("START:")
        state=[O1[], w1[],O2[], w2[]] #Warunki początkowe ze sliderów
        state[2], state[4]=start_forces!(state...) #Dodawanie sił z textboxów do danych kulek
        while true
            state, x1,y1,x2,y2=step!(state, dt) #obliczenia i aktualizacja wartości dla kolejnych stepów
            update!(x1,y1,x2,y2) #Rysowanie
            sleep(0.00001)
            if !isopen(fig.scene)
                return
            end
            if reset_clicked[]
                reset_clicked[]=false
                return
            end
        end
    end

    #Obsługa przycisku RUN
    on(start_button.clicks) do click
        if !is_running[]
            is_running[]=true
            start_button.label = "Running"
            @async begin
                if !isopen(fig.scene)
                    return
                end
                simulation() #start symulacji
                is_running[]=false
                start_button.label = "RUN"
            end
        end
    end
    #Obsługa przycisku reset
    on(reset_button.clicks) do click
        if is_running[]
            reset_clicked[]=true
        end
    end

    #Przycisk submit do ustawiania wartości sił z textboxów
    on(submit_button.clicks) do click
        global submit_button_clicked=true
        if !isnothing(textbox_fx.stored_string[])
            Fxmass[]=tryparse(Float64,textbox_fx.stored_string[])
            Fymass[]=tryparse(Float64,textbox_fy.stored_string[])
            println("Fxmass=$(Fxmass[]), Fymas=$(Fymass[])")
        end
    end

    spoint=select_point(axis.scene)#wykrywanie miejsca kliknięcia

    # Kliknięcie na wykresie
    on(spoint) do position
        cursor_pos=position
        # Sprawdzenie czy pozycja kursora jest blisko danej kulki
        # Ewentualne przypisywanie początkowych sił do danej kulki
        if mass_close((position[1], position[2]), mass1[])
            if submit_button_clicked==true
                println("Clicked on mass1")
                Fxmass1[]=Fxmass[]
                Fymass1[]=Fymass[]
                global submit_button_clicked=false
            end
        elseif mass_close((position[1], position[2]), mass2[])
            if submit_button_clicked==true
                println("Clicked on mass2")
                Fxmass2[]=Fxmass[]
                Fymass2[]=Fymass[]
                global submit_button_clicked=false
            end
        end
    end

    # Sprawdzenie czy kliknięcie jest blisko danej kulki z chatu GPT
    function mass_close(p1, p2, tol=0.05)
        return abs(p1[1]-p2[1])<tol && abs(p1[2]-p2[2])<tol
    end

    # Dodawanie sił przypisanych z SUBMIT do symulacji
    function start_forces!(θ1, ω1, θ2, ω2)
        a1=(Fxmass1[]*cos(θ1)+Fymass1[]*sin(θ1))/(m1[]*l1[])
        a2=(Fxmass2[]*cos(θ2)+Fymass2[]*sin(θ2))/(m2[]*l2[])
        ω1+=a1
        ω2+=a2
        return ω1, ω2
    end

    display(fig)

function julia_main()::Cint
    try
        main()
        return 0
    catch e
        @error "Error in main" exception=e
        return 1
    end
end

end # module
end