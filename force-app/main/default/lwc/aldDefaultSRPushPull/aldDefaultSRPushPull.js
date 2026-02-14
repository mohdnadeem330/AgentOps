import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import shouldPushOrPullApx from '@salesforce/apex/ALD_DandTSR_Handler_CC.shouldPushOrPullApx';
import pushPullTheSr from '@salesforce/apex/ALD_DandTSR_Handler_CC.pushPullTheSr';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';

export default class AldDefaultSRPushPull extends NavigationMixin(LightningElement) {

    @api recordId;
    showModal = false;
    inputObj = {header:'Push/Pull SR',ProcessOne:'Test',ProcessOneLabel:'Test Label',cancelBtnLabel:'Cancel'};
    showSpinner = false;
    toggleIconName = 'utility:internal_share';
    toggleIconName2 = '';
    toggleIconName3 = 'utility:success';
    showSuccess = false;
    errorMsg = '';
    disableSubmitButton = false;

    @wire(shouldPushOrPullApx, {recordId:'$recordId'})
    shouldPushOrPullFn({error, data}) {
        if (error) {
            console.log('error > ',error);
        } else if (data) {
            console.log('data > ',data);
            if(data.Success == 'Success') {
                
                this.inputObj.ProcessOne = data.ProcessOne;
                this.inputObj.ProcessOneLabel = data.ProcessOneLabel;
                this.showModal = true;
            } else if(data.Error == 'Error') {
                //this.handleToastMessage(data.ErrorMessage, 'error');
                this.handleAlertClick(data.ErrorMessage, 'error');
                this.handleCloseModal();
            }
            
        }
    }

    connectedCallback() {
        console.log('cmp loaded');
    }
    handlePushPullButton(event) {
        if(!this.disableSubmitButton) {
            let eventName = event.target.label;
            this._importJigJakLoader(eventName); //To Show JigJak
            let stepComment = this.template.querySelector('.comment_section');
            let recIds = [];
            recIds.push(this.recordId);
            this.disableSubmitButton = true;

            pushPullTheSr({eventName:eventName, recordIds:recIds, stepComment:stepComment.value})
            .then(result => {
                console.log('result > ',result);
                this.showSuccess = true;
                setTimeout(() => {
                    this.handleCloseModal();
                    this._navigateToSR();
                }, 500);

            })
            .catch(error => {
                console.log('error > ',error);
                let errorMsg = JSON.stringify(error);
                if(error.body.message!=undefined && error.body.message!='' && error.body.message!=null) {
                    errorMsg = error.body.message;
                }
                if(error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                    errorMsg = error.body.message.substring(82+('FIELD_CUSTOM_VALIDATION_EXCEPTION').length);
                    errorMsg = errorMsg.slice(0,errorMsg.indexOf(':'))
                }
                // TODO Error handling
                this.errorMsg = errorMsg;
                this.handleAlertClick(errorMsg, 'error');
                //this.handleCloseModal();
            });
        }

    }
    async handleAlertClick(errorMsg, aerror) {
        await LightningAlert.open({
            message: errorMsg,
            theme: aerror, // a red theme intended for error states
            label: 'Error!', // this is the header text
        });
        //Alert has been closed
        this.handleCloseModal();
    }
    handleCloseModal() {
        this.showModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleToastMessage(msg, status) {
        //this.handleToastMessage(error, 'error');

        const evt = new ShowToastEvent({
            title: msg,
            message: '',
            variant: status,
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }

    _importJigJakLoader(eventName) {
        this.showSpinner = true;
        if(eventName == 'Transfer to Legal') {
            
            this.toggleIconName = 'utility:macros';
            this.toggleIconName2 = 'utility:jump_to_right';

            for(let i=1;i<50;i++) {
                setTimeout(() => {
                    this.toggleIconName = i % 2 == 0 ? 'utility:macros' : 'utility:jump_to_right';
                    this.toggleIconName2 = i % 2 == 0 ? 'utility:jump_to_right' : 'utility:macros';
                }, 1000*i);
            }
        } else if(eventName == 'Pull from Legal') {
            this.toggleIconName = 'utility:macros';
            this.toggleIconName2 = 'utility:jump_to_right';

            for(let i=1;i<50;i++) {
                setTimeout(() => {
                    this.toggleIconName = i % 2 == 0 ? 'utility:macros' : 'utility:jump_to_right';
                    this.toggleIconName2 = i % 2 == 0 ? 'utility:jump_to_right' : 'utility:macros';
                }, 1000*i);
            }
        } else if(eventName == 'Transfer to D&T') {
            this.toggleIconName = 'utility:macros';
            this.toggleIconName2 = 'utility:jump_to_right';

            for(let i=1;i<50;i++) {
                setTimeout(() => {
                    this.toggleIconName = i % 2 == 0 ? 'utility:macros' : 'utility:jump_to_right';
                    this.toggleIconName2 = i % 2 == 0 ? 'utility:jump_to_right' : 'utility:macros';
                }, 1000*i);
            }
        }
    }

    _navigateToSR() {
        setTimeout(() => {
            window.location.reload();
            //eval("$A.get('e.force:refreshView').fire();");
       }, 2000); 
       /*this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'HexaBPM__Service_Request__c',
                actionName: 'view'
            },
        });*/
    }
}