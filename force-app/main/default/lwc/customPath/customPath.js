import { LightningElement, api, wire, track } from 'lwc';
import getPathStages from '@salesforce/apex/CustomPath.getPathStages';
import updateSelectedStage from '@salesforce/apex/CustomPath.updateSelectedStage';
import getCurrentStage from '@salesforce/apex/CustomPath.getCurrentStage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomPath extends LightningElement {
    @track pathStages;
    @track error;
    @api recordId; // The ID of the record being updated
    @api fieldApiName;
    @api pathFieldName = 'Status';
    havingPathValues;
    selectedStage;
    currentStage;
    descriptionLabel;
    descriptionVisible = false;
    ClosedDescription= false;
    Closedvalue = '';
    isLoading = false;

    get options() {
        return [
            { label: 'Closed Won', value: 'Closed Won' },
            { label: 'Closed Lost', value: 'Closed Lost' },
            { label: 'Settled', value: 'Settled' },
            { label: 'Duplicate', value: 'Duplicate' },
            { label: 'Rejected', value: 'Rejected' },
            { label: 'Lost in line with legal advice/recommendation', value: 'Lost in line with legal advice/recommendation' },
        ];
    }

    @wire(getPathStages, { recordId: '$recordId', fieldName: '$fieldApiName' })
    wiredPathStages({ error, data }) {
        if (data) {
            console.log('data in path:'+JSON.stringify(data));
            /*this.pathStages = data.map(stage => ({
                ...stage,
                name: stage,
                cssClass: 'slds-is-incomplete'
            }));*/
            this.pathStages = data;
            if(this.pathStages.length>0){
                this.havingPathValues = true;
            }else{
                this.havingPathValues = false;
            }
            console.log('pathStages:'+JSON.stringify(this.pathStages));
            console.log('this.havingPathValues:'+this.havingPathValues);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.pathStages = undefined;
        }
    }

    @wire(getCurrentStage, { recordId: '$recordId', pathFieldName: '$pathFieldName' })
    wiredCurrentStage({ error, data }) {
        if (data) {
            console.log('data in current stage:'+JSON.stringify(data));
            this.currentStage = data;
            this.error = undefined;
            this.descriptionLabel = data+' Description';
        } else if (error) {
            this.error = error;
            this.currentStage = undefined;
        }
    }


    handleSelectChange(event){
        event.preventDefault();
        this.currentStage = event.target.value;
        this.descriptionLabel = this.currentStage+' Description';
        if(this.currentStage==='Closed'){
            this.descriptionVisible = false;
            this.ClosedDescription = true;
        }else{
            this.descriptionVisible = true;
            this.ClosedDescription = false;
        }
        
    }
    handleChange(event){
        this.Closedvalue = event.target.value;
    }

    updateStage() {
        this.isLoading = true;
        var isValid = false;
        var descriptionVal = '';
        if(this.currentStage!='Closed'){
            const descriptionField = this.template.querySelector('lightning-input[data-id="description"]');
        
            if (!descriptionField.value) {
                descriptionField.setCustomValidity(this.descriptionLabel+' is required');
                isValid = false;
            }else{
                descriptionField.setCustomValidity('');
                isValid = true;
                descriptionVal = descriptionField.value;
            }
        }else{
            if(this.Closedvalue != ''){
                descriptionVal = this.Closedvalue;
                isValid=true;
            }else{
                isValid = false;
            }
        }
        
        if(isValid){
        updateSelectedStage({ recordId: this.recordId, selectedStage: this.currentStage, pathFieldName: this.pathFieldName, description : descriptionVal})
            .then(result => {
                if(result==='Success'){
                    this.isLoading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Stage updated successfully',
                            variant: 'success'
                        })
                    );
                    window.location.reload();
                }else{
                    this.isLoading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result,
                            variant: 'error'
                        })
                    );
                    setTimeout(() => {
                        // Refresh the page
                        window.location.reload();
                    }, 6000);
                }
                //this.currentStage = this.selectedStage;
            })
            .catch(error => {
                this.isLoading = false;
                this.error = error;
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error updating stage',
                        variant: 'error'
                    })
                );
            });
        }else{
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Description is required!',
                    variant: 'error'
                })
            );
        }
        this.isLoading = false;
        descriptionField.reportValidity();
       
    }

}