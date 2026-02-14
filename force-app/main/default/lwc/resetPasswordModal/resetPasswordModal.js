import { LightningElement } from 'lwc';
import resetPassowrd from '@salesforce/apex/UserProfileController.resetPassowrd';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';



export default class ResetPasswordModal extends LightningElement {

    closeModal(){
        this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false}}));
    }

    showToast(title, message, varaint, mode) {
        const event = new ShowToastEvent({
           title: title,
           message: message,
           variant: varaint,
           mode: mode
        });
        this.dispatchEvent(event);
     }

    // this will change after you made save action and based on passowrd action status will be reset
    submitDetails(){

        let newPassword = this.template.querySelector('[data-id="newPassword"]');
        let verifyNewPassword = this.template.querySelector('[data-id="verifyNewPassword"]');
        let oldPassword = this.template.querySelector('[data-id="oldPassword"]');

        resetPassowrd({newPassword: newPassword.value,  verifyNewPassword:verifyNewPassword.value , oldPassword:oldPassword.value})
        .then(data => {
            this.showToast('Success', 'Password updated Successfully', 'success', 'dismissable');
            this.closeModal();
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error', 'dismissable');
        });
        // this.dispatchEvent(new CustomEvent('successaction', {detail:{status:true}})); 
    }
    
}