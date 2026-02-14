import { LightningElement, track } from 'lwc';

export default class SearchUnitsWithStepper extends LightningElement {

    @track showSearchUnitStep=true;
    @track showLeadSelectionStep=false;
    @track showConfirmationStep=false;

    @track showUpdateDetailsStep=false;
  @track showPaymentPlansAndOffersStep=false;
    @track showReserveUnitConfirmationStep=false;
  
@track selectedSearchUnitName="";
    @track currentStep;
    @track  previousStep;
   
    @track currentStepperAarray;

selectedUnitsList=[];

@track reserveUnitFlag=false;

selectedunitsFromPaymentPlans;
connectedCallback(){


  
    //this.template.querySelector("c-custom-horizontal-stepper").canProceed=true;


// this.navigateBetweenComponents(this.currentStepperAarray,"searchUnit");
document.addEventListener('tabsetdatafromtheme', (e)=>{

    this.currentStep=e.detail.currentStep;
    this.previousStep=e.detail.previousStep;

    // console.log("############ component ###############",this.currentStep);
    // console.log("############ component ###############",this.previousStep);
    //for compare unit back
    if(this.currentStep == "searchUnit" && (this.previousStep == "compareUnits" || this.previousStep == "unitDetails")){
        this.template.querySelector("c-search-units").showCompareUnits=false;
        this.template.querySelector("c-search-units").showUnitsDetailsPage=false;
        
    }
    this.navigateBetweenComponents(this.currentStep);
    
 });


}
    stepperArrayForGenerateOffer = [
        { id: 1, label: "Property Selection", stepName:"searchUnit",index: 1, currentStepFlag: false, previousStepFlag: true, nexStepFlag: false ,stepperName:"generateOffer"},
        { id: 2, label: "Lead Selection", stepName:"leadSelection",index: 2, currentStepFlag: true, previousStepFlag: false, nexStepFlag: false,stepperName:"generateOffer" },
        { id: 3, label: "Confirmation",stepName:"offerGenerationConfirmation", index: 3, currentStepFlag: false, previousStepFlag: false, nexStepFlag: true, latestStepFlag: true ,stepperName:"generateOffer"},
       
    ];
    stepperArrayForReserveUnit= [
        { id: 1, label: "Property Selection", stepName:"searchUnit",index: 1, currentStepFlag: false, previousStepFlag: true, nexStepFlag: false,stepperName:"reserveUnit" },
        { id: 2, label: "Lead Selection", stepName:"leadSelection",index: 2, currentStepFlag: true, previousStepFlag: false, nexStepFlag: false,stepperName:"reserveUnit" },
        { id: 3, label: "Update Details",stepName:"updateDetails", index: 3, currentStepFlag: false, previousStepFlag: false, nexStepFlag: true, latestStepFlag: false,stepperName:"reserveUnit" },
        { id: 4, label: "Payment Plans And Offers",stepName:"paymentPlansAndOffers", index: 4, currentStepFlag: false, previousStepFlag: false, nexStepFlag: true, latestStepFlag: false,stepperName:"reserveUnit" },
        { id: 5, label: "Confirmation",stepName:"reserveUnitConfirmation", index: 5, currentStepFlag: false, previousStepFlag: false, nexStepFlag: true, latestStepFlag: true,stepperName:"reserveUnit" }
    
    ];

    getData(event){

        this.reserveUnitFlag=false;
        this.selectedUnitsList=event.detail.selected;
       
        
      
        this.currentStepperAarray=[...this.stepperArrayForGenerateOffer];
     

        this.showSearchUnitStep=false;
        this.showLeadSelectionStep=true;
        this.canProceed=true;// it will not reach here until the user select any row so the user can proceed
        
        this.navigateBetweenComponents("leadSelection");

    }
    getDataFromLeadSelection(event){
        
    
        this.showSearchUnitStep=false;
        this.showLeadSelectionStep=false;
        this.showConfirmationStep=event.detail.showConfirmationStep;
this.selectedRowFromLeadSelection=event.detail;



this.canProceed=event.detail.showConfirmationStep;

if(!event.detail.fromStepper){
    this.navigateBetweenComponents("offerGenerationConfirmation");
}

    }

  
    navigateBetweenComponents(stepName){
     
        switch(stepName){
         case "searchUnit":
        this.previousStep="";
        this.currentStep="searchUnit";
        this.showSearchUnitStep=true;
        this.showLeadSelectionStep=false;
        this.showConfirmationStep=false;
        
        this.showUpdateDetailsStep=false;
        this.showPaymentPlansAndOffersStep=false;
        this.showReserveUnitConfirmationStep=false;
        document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {currentStep:this.currentStep,previousStep:"" }}));
        this.syncWithStepper(1);
         break;
         case "leadSelection":
            this.previousStep="searchUnit";
            this.currentStep="leadSelection";
            this.showSearchUnitStep=false;
            this.showLeadSelectionStep=true;
            this.showConfirmationStep=false;
            this.showUpdateDetailsStep=false;
            this.showPaymentPlansAndOffersStep=false;
            this.showReserveUnitConfirmationStep=false;
            document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {currentStep:this.currentStep,previousStep:this.previousStep}}));
            this.canProceed=true;
            this.syncWithStepper(2);
        break;
        case "offerGenerationConfirmation":
            this.showSearchUnitStep=false;
            this.showLeadSelectionStep=false;
            this.showConfirmationStep=true;
            this.showUpdateDetailsStep=false;
            this.showPaymentPlansAndOffersStep=false;
            this.showReserveUnitConfirmationStep=false;
            this.previousStep="leadSelection";
            this.currentStep="offerGenerationConfirmation";
            document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {currentStep:this.currentStep,previousStep:this.previousStep }}));
            this.syncWithStepper(3);
        break;
        case "updateDetails":
            this.showSearchUnitStep=false;
            this.showLeadSelectionStep=false;
            this.showConfirmationStep=false;
            this.showUpdateDetailsStep=true;
            this.showPaymentPlansAndOffersStep=false;
            this.showReserveUnitConfirmationStep=false;
            this.previousStep="leadSelection";
            this.currentStep="updateDetails";
            document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {currentStep:this.currentStep,previousStep:this.previousStep }}));
            this.syncWithStepper(3);
        break;
        case "paymentPlansAndOffers":
            this.showSearchUnitStep=false;
            this.showLeadSelectionStep=false;
            this.showConfirmationStep=false;
            this.showUpdateDetailsStep=false;
            this.showPaymentPlansAndOffersStep=true;
            this.showReserveUnitConfirmationStep=false;
            this.previousStep="updateDetails";
            this.currentStep="paymentPlansAndOffers";
            document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {currentStep:this.currentStep,previousStep:this.previousStep }}));
            this.syncWithStepper(4);
        break;
        case "reserveUnitConfirmation":
            this.showSearchUnitStep=false;
            this.showLeadSelectionStep=false;
            this.showConfirmationStep=false;
            this.showUpdateDetailsStep=false;
            this.showPaymentPlansAndOffersStep=false;
            this.showReserveUnitConfirmationStep=true;
            this.previousStep="paymentPlansAndOffers";
            this.currentStep="reserveUnitConfirmation";
            document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {currentStep:this.currentStep,previousStep:this.previousStep }}));
            this.syncWithStepper(5);
        break;
        }
    }

    async syncWithStepper(stepNumber){
        let clickedItemIndex = stepNumber;
         if(this.activeStepIndex > clickedItemIndex || clickedItemIndex ==1 ){
             this.canProceed=true;
         }
         
       if (this.canProceed) {

       
           this.currentStepperAarray.forEach(element => {

                // console.log("element",element);
                if (element.index < clickedItemIndex) {
                    element.currentStepFlag = false;
                    element.previousStepFlag = true;
                    element.nexStepFlag = false;
                    
                }

                if (element.index == clickedItemIndex) {
                    element.currentStepFlag = true;
                    element.previousStepFlag = false;
                    element.nexStepFlag = false;
                this.activeStepIndex=clickedItemIndex;

              
                }

               

                if (element.index > clickedItemIndex) {
                    element.currentStepFlag = false;
                    element.previousStepFlag = false;
                    element.nexStepFlag = true;
                    
                }

            });
         
            this.currentStepperAarray=[...this.currentStepperAarray];
           
            let stpperComponent=this.template.querySelector("c-custom-horizontal-stepper");
            if(stpperComponent){
                stpperComponent.array=this.currentStepperAarray;
            
            }
           
         this.canProceed=false;

        } else if(!this.canProceed ){
            alert("Please fill or select mandatory fields first.");
        }
    }

    handleSelection(event){
     
        

        let clickedItemIndex = event.detail.childcomponentevent.currentTarget.dataset.selectionindex;
        let stepName=event.detail.childcomponentevent.currentTarget.dataset.stepname;

        

       
         if(this.activeStepIndex > clickedItemIndex){
             this.canProceed=true;
         }
      
       if (this.canProceed) {
        // console.log("---------currentStepperAarray----------------");
        // console.log(JSON.stringify(this.currentStepperAarray));
        // console.log("---------currentStepperAarray-----------------");
            this.currentStepperAarray.forEach(element => {

                if (element.index < clickedItemIndex) {
                    element.currentStepFlag = false;
                    element.previousStepFlag = true;
                    element.nexStepFlag = false;
                }

            

                if (element.index == clickedItemIndex) {
                    element.currentStepFlag = true;
                    element.previousStepFlag = false;
                    element.nexStepFlag = false;

                    // console.log("-------------------------");
                //    console.log(JSON.stringify(element));
                //    console.log("--------------------------");

                if(element.stepperName == "reserveUnit"){
                    this.navigateBetweenComponents(stepName);


                    if(clickedItemIndex ==3 && this.template.querySelector("c-lead-selection").selectedRows.length >1){
                        this.template.querySelector("c-lead-selection").canProceed=true;
                        this.canProceed=true;
                  
                        this.template.querySelector("c-lead-selection").goToTheUpdateDetailsStep(true);
                    }else if(clickedItemIndex ==4 && this.template.querySelector("c-update-details").canProceed ){
                        this.template.querySelector("c-update-details").goToTheReserveUnitConfirmationStep(true);
                    }
                }else if(element.stepperName == "generateOffer"){
                    
                    this.navigateBetweenComponents(stepName);

                    if(clickedItemIndex ==3 && this.template.querySelector("c-lead-selection").selectedRows.length >1){
                        this.template.querySelector("c-lead-selection").canProceed=true;
                        this.canProceed=true;
                  
                        this.template.querySelector("c-lead-selection").goToTheConfirmationStep2(true);
                    }
                }

                this.activeStepIndex=clickedItemIndex;
            
                    
                
                }

                if (element.index > clickedItemIndex) {
                    element.currentStepFlag = false;
                    element.previousStepFlag = false;
                    element.nexStepFlag = true;
                   
                }

            });

            
           


            this.stepperArray=[...this.stepperArray];
            this.template.querySelector("c-custom-horizontal-stepper").array=this.stepperArray;
         this.canProceed=false;

        } else if(!this.canProceed ){
            alert("Please fill or select mandatory fields first.");
        }
  

    }


    getSelectedToReserve(event){
       
 let data=event.detail;
this.selectedSearchUnitName=data.name;
//  console.log("~~~~~~~~~~~~~~~~~~~~~~~~~~");
// console.log(JSON.stringify(data));
//  console.log("~~~~~~~~~~~~~~~~~~~~~~~~~~");
this.reserveUnitFlag=true;
this.currentStepperAarray=[...this.stepperArrayForReserveUnit];
this.navigateBetweenComponents("leadSelection");

    }

    getSelectedUnits(event){
       this.selectedunitsFromPaymentPlans=event.detail.selectedList;

       this.previousStep="paymentPlansAndOffers";
       this.currentStep="reserveUnitConfirmation";

       this.showSearchUnitStep=false;
       this.showLeadSelectionStep=false;
       this.showConfirmationStep=false;
       this.showUpdateDetailsStep=false;
       this.showPaymentPlansAndOffersStep=false;
       this.showReserveUnitConfirmationStep=true;

       if(!event.detail.fromStepper){
        this.navigateBetweenComponents("reserveUnitConfirmation");
    }
    }


    checkCanproceedValue(event){
        this.canProceed=event.detail.canproceed;
    }

    checkCanproceedValue1(event){
        this.canProceed=event.detail.canproceed;
     
    }

    checkCanproceedValue2(event){
        this.canProceed=event.detail.canproceed;

    }


    checkCanproceedValue3(event){
        this.canProceed=event.detail.canproceed;
    
    }


}