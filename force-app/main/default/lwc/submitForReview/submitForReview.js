import { LightningElement, api } from 'lwc';
import submitforReview from '@salesforce/apex/PIOpportunitySubmissionController.submitOpportunity';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class SubmitForReview extends LightningElement {
    value = '';
    @api recordId;
    isLoading = false;
    handleClick(){
        this.isLoading = true;
        // const contentBlockClasslist = this.template.querySelector('.reviewButton').value;
        //     console.log('value' + contentBlockClasslist);
        // if(contentBlockClasslist === 'review'){
            submitforReview({
                opportunityId: this.recordId
            }).then(response => {
                this.isLoading = false;
                console.log('mail sent' + response);
                // this.checkforphone = response;
    
                // var phTemp = this.template.querySelector('.phone-check');
                // if (this.checkforphone) {
                //     phTemp.setCustomValidity('');
                // } else {
                //     phTemp.setCustomValidity('You have enter incorrect Mobile No');
                // }
                // phTemp.reportValidity();
                if(response){
                    this.dispatchEvent(new CloseActionScreenEvent());
                    const evt = new ShowToastEvent({
                        title: 'Submission Failed because '+response+' documents are missing.',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }else{
                    this.dispatchEvent(new CloseActionScreenEvent());
                    const evt = new ShowToastEvent({
                        title: 'Submitted Successfully',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                    window.location.href = window.location.origin+"/"+this.recordId;
                }
                
            }).catch(error => {
                console.log('Error: ' + error.body.message);
                this.dispatchEvent(new CloseActionScreenEvent());
                const evt = new ShowToastEvent({
                    title: 'Submission Failed',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            });
        // }else{
        //     this.dispatchEvent(new CloseActionScreenEvent());
        //     const evt = new ShowToastEvent({
        //         title: 'Submission Failed',
        //         variant: 'error',
        //     });
        //     this.dispatchEvent(evt);
        // }
    
    }
    handleNo(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    get options() {
        return [
            { label: 'review', value: 'review' }
        ];
    }
}