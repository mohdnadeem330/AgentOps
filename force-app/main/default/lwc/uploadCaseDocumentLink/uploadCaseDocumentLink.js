import { LightningElement, api } from 'lwc';
import generateAndSaveEncryptedKey from '@salesforce/apex/UploadDocumentLinkController.generateAndSaveEncryptedKey';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import EXPERIENCE_BASE_URL from '@salesforce/label/c.Experience_Base_URL';

export default class UploadCaseDocumentLink extends LightningElement {

    @api recordId; // Case Id
    experienceUrl;

    isLoading = false; // 🔄 Loader flag

    get generateButtonLabel() {
        return this.isLoading ? 'Generating…' : 'Generate Link';
    }

    handleGenerate() {
        this.isLoading = true;

        generateAndSaveEncryptedKey({ caseId: this.recordId })
            .then(encryptedKey => {
                this.experienceUrl = `${EXPERIENCE_BASE_URL}?key=${encryptedKey}`;
                this.showToast(
                    'Success',
                    'Link generated successfully',
                    'success'
                );
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    error.body?.message || 'Something went wrong',
                    'error'
                );
            })
            .finally(() => {
                this.isLoading = false; // ✅ Hide loader
            });
    }

    handleCopy() {
        if (!this.experienceUrl) {
            return;
        }

        try {
            // 🔹 Create hidden textarea
            const textarea = document.createElement('textarea');
            textarea.value = this.experienceUrl;

            // Avoid scrolling to bottom
            textarea.style.position = 'fixed';
            textarea.style.opacity = '0';

            document.body.appendChild(textarea);
            textarea.select();

            // 🔹 Execute copy
            document.execCommand('copy');

            document.body.removeChild(textarea);

            this.showToast('Copied', 'Link copied to clipboard', 'success');

        } catch (e) {
            this.showToast('Error', 'Unable to copy link', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}