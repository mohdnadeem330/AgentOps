import { api, LightningElement, track } from 'lwc';

export default class CustomTimer extends LightningElement {

    pageVisisted = new Date(); // you should probably store this in a database/attach it to the session or AT LEAST in a cookie



    
    result;
    @api redirectTo;
    @api startFrom;
    @api maxIntervalNumbers;
    showConfirmationButtons=true;

    alertMessage="Do you want to complete active";

    showAlertMessage=false;


intervalCount=0;


    //connectedCallback(){ this.timer()}
    connectedCallback(){ 
        this.initializeTimer();
        
    
    }


    initializeTimer(){
        if(this.startFrom != 0  && this.startFrom != null & this.startFrom != undefined){
            this.timer(Number(this.startFrom));
    
        }else{
            this.timer(8);
        }
    }
 

    timer(duration) {
        duration=duration*60;
    
       
        var timer = duration, minutes, seconds;
        const interval=setInterval(()=>{
            minutes = parseInt(timer / 60, 10);
            seconds = parseInt(timer % 60, 10);
    
            minutes = minutes < 10 ? "0" + minutes : minutes;
            seconds = seconds < 10 ? "0" + seconds : seconds;
    
            this.result = minutes + ":" + seconds;

            
            if (--timer < 0) {
                timer = duration;
                this.intervalCount+=1;
               
                if(this.maxIntervalNumbers == 0 || this.maxIntervalNumbers == undefined || this.maxIntervalNumbers == null){
                    this.maxIntervalNumbers=4;
                }
                if(this.intervalCount == parseInt(this.maxIntervalNumbers)){
                    this.showAlertMessage=true;
                }

            }
        }, 1000);
    }

    closeModal(event){
        this.showAlertMessage=event.detail.isOpen;
        
    }


    keepLoggedInOrNot(event){


        // 24 minutes redirect to another link 
  

     if(event.detail.stayLoggedIn){
         this.intervalCount=0;
       // this.pageVisisted=new Date();
        //if(this.intervalCount !=24){
       this.initializeTimer();
    //}
        this.showAlertMessage=false;
    }else{
       // window.location.replace("https://prdev-aldarprdev.cs81.force.com/pr2/servlet/networks/switch?startURL=%2Fsecur%2Flogout.jsp");
       if(this.redirectTo){
       window.location.replace(this.redirectTo);
     
    }else{
        alert("You didn't specify any URL to redirect to, so we woll reset the timer");
        this.initializeTimer();
    }
    }

    }

//     timer2(){

//         const interval=setInterval(()=>{
//             this.timeOnSite = new Date() - this.pageVisisted;
           
//             this.secondsTotal = this.timeOnSite / 1000;
//             this.hours = Math.floor(this.secondsTotal / 3600);
//             this.minutes = Math.floor(this.secondsTotal / 60) % 3600;
//            this.seconds = Math.floor(this.secondsTotal)  % 60;
           
//            this.result = this.hours + ":" + this.minutes + ":" + this.seconds;
        
           
//            if(this.minutes == 8){
//             this.totalMinutes+=8;

// clearInterval(interval);
// if(this.totalMinutes == 24){
//     if(this.redirectTo){
//     window.location.replace(this.redirectTo);
//     }else{
        
//     }
// }
// this.showAlertMessage=true;

//            }

//        }, 1000);
//     }

   

}