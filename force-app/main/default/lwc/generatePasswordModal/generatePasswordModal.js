import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generatepassword from '@salesforce/apex/BrokerAgentsController.generatepassword';
import { NavigationMixin } from 'lightning/navigation';
import saveTheFile from '@salesforce/apex/LEX_UploadDocumentsController.saveTheFile';

export default class GeneratePasswordModal extends NavigationMixin(LightningElement) {

  @track generatePassword;
  @track password;
  @track passwordLength;
  @track passwordNumber;
  @track passwordLetter;
  @track passwordUpperLetter;
  @track generatePwd;
  @api recordId;
  @api userEmail;
  @track showHelpText;
  @track showSpinner=false;


  closeModal() {
    
    this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));
  }

  /* handleFocus(){
     this.showHelpText=true;
   }*/

  handlePassword(event) {
    this.password = event.target.value;

  }

  handleBlurPassword(event) {
    this.showHelpText = true;
    var numbers = /[0-9]/g;
    var lowerCaseletters = /[a-z]/g;
    var upperCaseletters = /[A-Z]/g;

    let getPassword = this.template.querySelector(".password");
    //validate length

    if (!this.password || this.password.length == 0) {

      getPassword.setCustomValidity('Please enter password');

    } else if (this.password.length < 8) {

      getPassword.setCustomValidity('Password must contain atleast  8 characters');

    } else if (!this.password.match(numbers)) {

      getPassword.setCustomValidity('Password must contain  one number');

    }
    else if (!this.password.match(lowerCaseletters)) {
      getPassword.setCustomValidity('Password must contain  a lowercase letter');
    }
    else if (!this.password.match(upperCaseletters)) {

      getPassword.setCustomValidity('Password must contain  a uppercase letter');

    }

    else {
      getPassword.setCustomValidity('');

    }
    getPassword.reportValidity();

    let confirmPassword = this.template.querySelector(".generatePassword");
    if (this.password != this.generatePassword && (this.generatePassword || this.generatePassword.length > 0)) {
      confirmPassword.setCustomValidity('Password not matched');
    } else if (this.password.length > 0 && this.generatePassword.length > 0 && this.password == this.generatePassword) {
      confirmPassword.setCustomValidity('');
    }
    confirmPassword.reportValidity();



  }

  handleGeneratePassword(event) {
    this.showHelpText = false;
    this.generatePassword = event.target.value;

  }

  submitDetails() {

    this.showSpinner=true;
    if (!this.password || !this.generatePassword) {
      this.showToast('Error', 'Please enter password', 'error', 'dismissable');
    }

    generatepassword({ userId: this.recordId, newPassword: this.generatePassword, userEmail: this.userEmail }).then(result => {
      this.showToast('Success', 'Password generated successfully', 'success', 'pester');
      this.isGeneratePasswordModalOpen();
      this.showSpinner=false;
    }).catch(error => {
      this.showSpinner=false;
      var errMessage = JSON.stringify(error);
      console.error('error%%%%%%%%%%%>>' + errMessage);
      if (errMessage.includes('repeated password')) {
        this.showToast('Error', 'You can\'t used old password.', 'error', 'dismissable');

      }
      if (errMessage.includes(' user is inactive')) {
        this.showToast('Error', 'You can\'t generate password for inactive user.', 'error', 'dismissable');

      }
    })
  }

  isGeneratePasswordModalOpen() {
    this.dispatchEvent(new CustomEvent('closemodal', { detail: false }));
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
}