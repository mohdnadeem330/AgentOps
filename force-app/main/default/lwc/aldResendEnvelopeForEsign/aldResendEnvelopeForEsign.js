import { LightningElement, wire, track, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getStepDetails from '@salesforce/apex/AgencyRegDocuSignHelper.getStepDetails';
import sendUsingDocuSignFuture from '@salesforce/apex/AgencyRegDocuSignHelper.sendUsingDocuSignFuture';

export default class AldResendEnvelopeForEsign extends NavigationMixin(LightningElement)
{
    @api recordId;
    stepId;
    toggleIconName = '';
    toggleIconName2 = '';

    async connectedCallback()
    {
        let serviceRequestIdURL = this.recordId && this.recordId != null ? this.recordId : new URL(window.location.href).searchParams.get("recordId");
        console.log('serviceRequestIdURL---->>>' + serviceRequestIdURL);

        if(serviceRequestIdURL != null)
        {
            this.processingAnimation();

            await getStepDetails({ srId: serviceRequestIdURL })
            .then(result => {
                console.log('Result', result);
                this.stepId = result;
            })
            .catch(error => {
                console.error('Error:', error);
            });

            
            await sendUsingDocuSignFuture({ srId: serviceRequestIdURL, stepId: this.stepId, docCode: 'Agency_Agreement_Document' })
            .then(result => {
                console.log('Result', result);
                this.handleCloseModal();
                this.showToast('Success', 'Successfully created new Envelope', 'success');
            })
            .catch(error => {
                this.handleCloseModal();
                console.error('Error:', error);
                this.showToast('Error', 'Some Error Occured:'+error, 'error');
            });
            

        }

    }

    showToast(title, message, variant)
    {
        const event = new ShowToastEvent({
            title       :   title,
            message     :   message,
            variant     :   variant,
            mode        :   'sticky'
        });
        this.dispatchEvent(event);
    }

    handleCloseModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    processingAnimation()
    {
        this.showSpinner = true;
        this.toggleIconName = 'utility:macros';
        this.toggleIconName2 = 'utility:jump_to_right';

        for(let i = 1; i < 500 ; i++) {
            setTimeout(() => {
                this.toggleIconName = i % 2 == 0 ? 'utility:macros' : 'utility:jump_to_right';
                this.toggleIconName2 = i % 2 == 0 ? 'utility:jump_to_right' : 'utility:macros';
            }, 1000*i);
        }
    }


}