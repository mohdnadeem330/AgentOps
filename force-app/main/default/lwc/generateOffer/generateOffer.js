import { LightningElement, track } from 'lwc';

export default class GenerateOffer extends LightningElement {

    @track showSearchUnitStep=true;
    @track showLeadSelectionStep=false;
    @track showConfirmationStep=false;

    @track currentStep;
    @track  previousStep;
   
selectedUnitsList=[];


stepperArray = [
    { id: 1, label: "Property Selection", stepName:"searchUnit",index: 1, currentStepFlag: false, previousStepFlag: true, nexStepFlag: false },
    { id: 2, label: "Lead Selection", stepName:"leadSelection",index: 2, currentStepFlag: true, previousStepFlag: false, nexStepFlag: false },
    { id: 3, label: "Confirmation",stepName:"offerGenerationConfirmation", index: 3, currentStepFlag: false, previousStepFlag: false, nexStepFlag: true, latestStepFlag: true }

]

dataFromSearchUnit;
dataFromLeadSelection;
childRow;
selectedRowFromLeadSelection;
canProceed=false;
activeStepIndex=1;
connectedCallback(){


  
        //this.template.querySelector("c-custom-horizontal-stepper").canProceed=true;

  
    this.navigateBetweenComponents("searchUnit");
	document.addEventListener('tabsetdatafromtheme', (e)=>{

        this.currentStep=e.detail.currentStep;
        this.previousStep=e.detail.previousStep;

        console.log("############ component ###############",this.currentStep);
		console.log("############ component ###############",this.previousStep);

        this.navigateBetweenComponents(this.currentStep);
        
     });


   

   


}
    getData(event){

        this.selectedUnitsList=event.detail.selected;

console.log("================>",JSON.stringify(this.selectedUnitsList));


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


console.log("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
console.log(this.selectedRowFromLeadSelection);
console.log(JSON.stringify(this.selectedRowFromLeadSelection));
console.log(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");

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
        document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {currentStep:this.currentStep,previousStep:"" }}));
        this.syncWithStepper(1,stepName);
         break;
         case "leadSelection":
            this.previousStep="searchUnit";
            this.currentStep="leadSelection";
            this.showSearchUnitStep=false;
            this.showLeadSelectionStep=true;
            this.showConfirmationStep=false;
            document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {currentStep:this.currentStep,previousStep:this.previousStep}}));
            this.canProceed=true;
            this.syncWithStepper(2,stepName);
        break;
        case "offerGenerationConfirmation":
            this.showSearchUnitStep=false;
            this.showLeadSelectionStep=false;
            this.showConfirmationStep=true;
            this.previousStep="leadSelection";
            this.currentStep="offerGenerationConfirmation";
            document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {currentStep:this.currentStep,previousStep:this.previousStep }}));
            this.syncWithStepper(3,stepName);
        break;
        }
    }


    async syncWithStepper(stepNumber,stepName2){
        
        let clickedItemIndex = stepNumber;
        let stepName=stepName2;


      
    
         if(this.activeStepIndex > clickedItemIndex || clickedItemIndex ==1 ){
             this.canProceed=true;
         }
         
       if (this.canProceed) {

       
            this.stepperArray.forEach(element => {

                console.log("element",element);
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
         
            this.stepperArray=[...this.stepperArray];
           
            let stpperComponent=this.template.querySelector("c-custom-horizontal-stepper");
            if(stpperComponent)stpperComponent.array=this.stepperArray;
           
         this.canProceed=false;

        } else if(!this.canProceed ){
            alert("Please fill or select mandatory fields first.");
        }

        
        
       
    }
    


    handleSelection(event) {
     
        

        let clickedItemIndex = event.detail.childcomponentevent.currentTarget.dataset.selectionindex;
        let stepName=event.detail.childcomponentevent.currentTarget.dataset.stepname;

        

       
         if(this.activeStepIndex > clickedItemIndex){
             this.canProceed=true;
         }
      
       if (this.canProceed) {
            this.stepperArray.forEach(element => {

                if (element.index < clickedItemIndex) {
                    element.currentStepFlag = false;
                    element.previousStepFlag = true;
                    element.nexStepFlag = false;
                }

                if (element.index == clickedItemIndex) {
                    element.currentStepFlag = true;
                    element.previousStepFlag = false;
                    element.nexStepFlag = false;

                    this.navigateBetweenComponents(stepName);
                    
                    
                this.activeStepIndex=clickedItemIndex;
             if(clickedItemIndex ==3 && this.template.querySelector("c-lead-selection").selectedRows.length >1){
                    this.template.querySelector("c-lead-selection").canProceed=true;
                    this.canProceed=true;
              
                    this.template.querySelector("c-lead-selection").goToTheConfirmationStep2(true);
                }
                    
                
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

    



    fillData(stepName){


        if(stepName == "leadSelection"){
          
            if(this.selectedRowFromLeadSelection !=undefined){
              setTimeout(() => {
                 let parentRow=this.selectedRowFromLeadSelection.selected.parentRow;
                 let childRow=this.selectedRowFromLeadSelection.selected.childRow
                 //this.selectedRowFromLeadSelection.selected.childRow.split("-")[0];
                let arr=[];
                arr.push(parentRow);
                arr.push(childRow);

                this.template.querySelector("c-lead-selection").gridExpandedRows=[...[parentRow]];

                this.template.querySelector("c-lead-selection").selectedRows.push(parentRow);
                this.template.querySelector("c-lead-selection").selectedRows.push(childRow);
               
                this.template.querySelector("c-lead-selection").selectedRows=[...arr];
             }, 2000);
                
            }
        }else if(stepName == "searchUnit"){

        }

    }


    checkCanproceedValue(event){

        this.canProceed=event.detail.canproceed;
        
    }
}