import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { CurrentPageReference } from 'lightning/navigation';
import getServiceRequestDetails from '@salesforce/apex/PaymentPlanFromSRController.getServiceRequestDetails';
import getInstallmentLines from '@salesforce/apex/PaymentPlanFromSRController.getInstallmentLines';
import InstallmentNumber_FIELD from '@salesforce/schema/InstallmentLines__c.InstallmentNumber__c';
import InstallmentPercentage_FIELD from '@salesforce/schema/InstallmentLines__c.InstallmentPercentage__c';
import InstallmentDate_FIELD from '@salesforce/schema/InstallmentLines__c.InstallmentDate__c';
import InstallmentAmount_FIELD from '@salesforce/schema/InstallmentLines__c.InstallmentAmount__c';
import createBookingMemo from '@salesforce/apex/PaymentPlanFromSRController.createBookingMemo';
import getBookingMemoDetails from '@salesforce/apex/PaymentPlanFromSRController.getBookingMemoDetails';
import getInstallmentLineChangesDetails from '@salesforce/apex/PaymentPlanFromSRController.getInstallmentLineChangesDetails';
import getServiceRequestStep from '@salesforce/apex/PaymentPlanFromSRController.getServiceRequestStep';
import updateInstallmentChangesRecords from '@salesforce/apex/PaymentPlanFromSRController.updateInstallmentChangesRecords';
import completeServiceRequestStep from '@salesforce/apex/PaymentPlanFromSRController.completeServiceRequestStep';
import getListOfPaymentPlans from '@salesforce/apex/PaymentPlanFromSRController.getListOfPaymentPlans';

export default class PaymentPlanFromSR extends NavigationMixin(LightningElement) {

    @api recordId;
    @track errorMessageToDisplay = '';
    @track errorHeader = 'Error Message';
    @track error = { message: '' };
    @track isLoaded = false;
    @track index = 0;
    @track accountList = [];
    @track installmentList = [];
    @track srRecord;
    @track stepRecord;
    @track InstallmentNumber = InstallmentNumber_FIELD;
    @track InstallmentPercentage = InstallmentPercentage_FIELD;
    @track InstallmentDate = InstallmentDate_FIELD;
    @track InstallmentAmount = InstallmentAmount_FIELD;
    @track totalPercentage = 0;
    @track totalAmount = 0;
    @track discountPercentage = 0;
    @track discountAmount = 0;
    @track rebatePercentage = 0;
    @track rebateAmount = 0;
    @track sellingPrice = 0
    @track netSellingPrice = 0
    @track readOnlyScreen = false;
    @track memoLineRecord;
    @track oldInstallmentCount = 0
    @track totalAmountPending = 0;
    @track salesOrderRecord;
    @track unitRecord;
    @track paymentPlanChoosed = '';
    @track listOfPaymentPlans;
    @track paymentInstallments = [];
    @track newInstallmentList = [];
    @track bulkDiscount = 0;
    @track paymentPlanDiscount = 0;
    @track corporateWealthDiscount = 0;
    @track discountBy = 'Percentage';
    @track discountAmountReadOnly = true;
    @track discountPercentageReadOnly = false;
    @track rebateBy = 'Percentage';
    @track rebateAmountReadOnly = true;
    @track rebatePercentageReadOnly = false;
    @track installmentPercentOrAmount = 'Percentage';
    @track installmentAmountReadOnly = true;
    @track installmentPercentageReadOnly = false;

    acc = {
        Name: this.Name,
        AccountNumber: this.accNumber,
        Phone: this.phone ? this.phone : "",
        key: ''
    }
    installment = {
        Number: this.InstallmentNumber,
        Percentage: this.InstallmentPercentage,
        Date: null,
        Amount: this.InstallmentAmount,
        readonly: false,
        key: '',
        Id: '',
        PercentageReadOnly: this.installmentPercentOrAmount == 'Percentage' ? false : true,
        AmountReadOnly: this.installmentPercentOrAmount == 'Amount' ? false : true,
        Description: ''
    }

    @track paymentPlanOptions = [{ label: '', value: '' }];
    @track discountByOptions = [{ label: 'Amount', value: 'Amount' }, { label: 'Percentage', value: 'Percentage' }];

    get paymentPlanOptionsValues() {
        return this.paymentPlanOptions
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    async connectedCallback() {
        this.isLoaded = true;

        getServiceRequestDetails({ recordId: this.recordId }).then(result => {
            this.srRecord = result;
            this.sellingPrice = this.srRecord.SalesOrder__r.NetAmount__c;
            this.netSellingPrice = this.srRecord.SalesOrder__r.NetAmount__c;
            this.salesOrderRecord = this.srRecord.SalesOrder__r;
            this.unitRecord = this.srRecord.Unit__r;
            this.bulkDiscount = this.srRecord.SalesOrder__r.BulkDiscount__c;
            this.paymentPlanDiscount = this.srRecord.SalesOrder__r.PaymentPlanDiscount__c;
            this.corporateWealthDiscount = this.srRecord.SalesOrder__r.CorporateDiscount__c > 0 ? this.srRecord.SalesOrder__r.CorporateDiscount__c : this.srRecord.SalesOrder__r.WealthDiscount__c > 0 ? this.srRecord.SalesOrder__r.WealthDiscount__c : 0;
            this.paymentPlanOptions[0].label = this.srRecord.PaymentPlan__c == null ? '' : this.srRecord.PaymentPlan__r.Name + ' (Current)';
            this.paymentPlanOptions[0].value = this.srRecord.PaymentPlan__c == null ? '' : this.srRecord.PaymentPlan__r.Name;
            console.log('unitRecord: ' + JSON.stringify(this.unitRecord));

            var srStatus = ["Request Verified", "Rejected", "Submitted", "Draft", "Generate CCA", "Agreement Signed", "Approved by CCC"];

            if (srStatus.indexOf(this.srRecord.HexaBPM__External_Status_Name__c) == -1) {
                this.netSellingPrice = this.srRecord.NewNetAmount__c;
                this.discountAmount = parseFloat((this.srRecord.SalesOrder__r.Discount__c).toFixed(2));
                this.discountPercentage = this.discountAmount != 0 ? parseFloat((this.sellingPrice / this.discountAmount).toFixed(2)) : 0;
                if (this.srRecord.SalesOrder__r.OtherRebateAmount__c) {
                    this.rebateAmount = parseFloat((this.srRecord.SalesOrder__r.OtherRebateAmount__c).toFixed(2));
                }
                this.rebatePercentage = this.rebateAmount != 0 ? parseFloat((this.sellingPrice / this.rebateAmount).toFixed(2)) : 0;
            }
            getListOfPaymentPlans({ unit: this.unitRecord }).then(result => {

                console.log('getListOfPaymentPlans:');
                console.log(result);

                this.listOfPaymentPlans = result;

                result.forEach(element => {
                    this.paymentPlanOptions = [...this.paymentPlanOptions, { value: element.Name, label: element.Name }];
                });

            }).catch(error => {
                this.error = error;
                this.reduceErrors(error);
                this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                this.isLoaded = false;
            })

            if (this.srRecord.ProposalPaymentPlan__c != null) {

                getBookingMemoDetails({ bookingMemoId: this.srRecord.ProposalPaymentPlan__c }).then(result => {

                    this.memoLineRecord = result;
                    this.discountPercentage = result.DiscountPercentage__c;
                    this.rebatePercentage = result.RebatePercentage__c;
                    this.discountAmount = this.sellingPrice * (this.discountPercentage / 100);
                    this.rebateAmount = this.sellingPrice * (this.rebatePercentage / 100);
                    this.netSellingPrice = this.sellingPrice - this.discountAmount;

                    getInstallmentLineChangesDetails({ bookingMemoId: this.srRecord.ProposalPaymentPlan__c }).then(result => {
                        result.forEach(element => {

                            var readonly = false;
                            if (element.InstallmentDate__c != null) {
                                readonly = true;
                            }
                            this.installmentList.push({
                                Number: element.InstallmentNumber__c,
                                Percentage: parseFloat(parseFloat(element.ProposedInstallmentPercentage__c).toFixed(2)),
                                Date: element.ProposedInstallmentDate__c,
                                Amount: parseFloat(parseFloat(element.InstallmentAmount__c).toFixed(2)),
                                readonly: readonly,
                                key: this.index,
                                Id: element.Id,
                                PercentageReadOnly: readonly,
                                AmountReadOnly: true,
                                Description: element.Description__c
                            })

                            this.totalPercentage = parseFloat((this.totalPercentage + parseFloat(element.ProposedInstallmentPercentage__c)).toFixed(2));
                            this.totalAmount = parseFloat((this.totalAmount + parseFloat(element.InstallmentAmount__c)).toFixed(2));
                            this.index++;
                        });

                        this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));

                        getServiceRequestStep({ serviceRequestId: this.srRecord.Id }).then(result => {

                            this.stepRecord = result;
                            if (result == null) {
                                this.readOnlyScreen = false;

                            } else if (result.HexaBPM__Summary__c != 'Verify the Request' && result.HexaBPM__Summary__c != 'Approve the Request') {
                                this.readOnlyScreen = true;
                                this.discountAmountReadOnly = true;
                                this.discountPercentage = true;
                            }

                            this.isLoaded = false;

                        }).catch(error => {
                            this.error = error;
                            this.reduceErrors(error);
                            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                            this.isLoaded = false;
                        })

                    }).catch(error => {
                        this.error = error;
                        this.reduceErrors(error);
                        this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                        this.isLoaded = false;
                    })

                }).catch(error => {
                    this.error = error;
                    this.reduceErrors(error);
                    this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                    this.isLoaded = false;
                })

            } else {

                this.discountAmount = this.sellingPrice * (this.discountPercentage / 100);
                this.rebateAmount = this.sellingPrice * (this.rebatePercentage / 100);
                this.netSellingPrice = this.sellingPrice - this.discountAmount;
                getInstallmentLines({ salesorderId: this.srRecord.SalesOrder__c }).then(result => {

                    console.log(this.netSellingPrice);

                    result.forEach(element => {

                        var readonly = false;
                        if (element.OutstandingAmount__c == 0 || element.OutstandingAmount__c != element.InstallmentAmount__c) {
                            readonly = true;
                        }


                        this.installmentList.push({
                            Number: element.InstallmentNumber__c,
                            Percentage: parseFloat((element.InstallmentAmount__c / this.netSellingPrice * 100).toFixed(2)),
                            Date: element.InstallmentDate__c,
                            Amount: parseFloat(parseFloat(element.InstallmentAmount__c).toFixed(2)),
                            readonly: readonly,
                            key: this.index,
                            PercentageReadOnly: readonly,
                            AmountReadOnly: true,
                            Description: element.Description__c
                        })

                        this.totalPercentage = this.totalPercentage + parseFloat((element.InstallmentAmount__c / this.netSellingPrice * 100).toFixed(2));
                        this.totalAmount = parseFloat((this.totalAmount + parseFloat(element.InstallmentAmount__c)).toFixed(2));
                        this.index++;
                    });
                    this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
                    this.oldInstallmentCount = this.index + 1;


                    if (this.totalAmountPending != 0) {
                        this.installmentList[this.installmentList.length - 1].Amount += parseFloat((this.totalAmountPending).toFixed(2));
                        this.totalAmount = parseFloat((this.totalAmount + this.totalAmountPending).toFixed(2));
                        this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
                    }
                    if (this.totalPercentage != 100) {
                        this.installmentList[this.installmentList.length - 1].Percentage += parseFloat((100 - this.totalPercentage).toFixed(2));
                        this.totalPercentage = parseFloat((this.totalPercentage + (100 - this.totalPercentage)).toFixed(2));
                    }

                    getServiceRequestStep({ serviceRequestId: this.srRecord.Id }).then(result => {

                        this.stepRecord = result;
                        console.log(result);

                        if (result == null) {
                            this.readOnlyScreen = false;

                        } else if (result.HexaBPM__Summary__c != 'Verify the Request' && result.HexaBPM__Summary__c != 'Approve the Request') {
                            this.readOnlyScreen = true;
                            this.discountAmountReadOnly = true;
                            this.discountPercentage = true;
                        }

                        this.isLoaded = false;

                    }).catch(error => {
                        this.error = error;
                        this.reduceErrors(error);
                        this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                        this.isLoaded = false;
                    })

                }).catch(error => {
                    this.error = error;
                    this.reduceErrors(error);
                    this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                    this.isLoaded = false;
                })
            }

        }).catch(error => {
            this.error = error;
            this.reduceErrors(error);
            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
            this.isLoaded = false;
        })
    }

    percentageOrAmount() {

    }

    addRow() {

        this.index++;
        var i = this.index;
        this.installment.key = i;
        this.installment.Number = i;
        this.installment.Amount = 0;
        this.installment.Percentage = 0;
        this.installment.AmountReadOnly = this.installmentPercentOrAmount == 'Amount' ? false : true;
        this.installment.PercentageReadOnly = this.installmentPercentOrAmount == 'Percentage' ? false : true;

        if (this.newInstallmentList.length > 0) {
            this.newInstallmentList.push(JSON.parse(JSON.stringify(this.installment)));
        } else {
            this.installmentList.push(JSON.parse(JSON.stringify(this.installment)));
        }
    }

    addRowFromElement(event) {

        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;

        console.log(selectedRow);
        console.log(JSON.stringify(selectedRow));
        console.log(JSON.stringify(selectedRow.dataset));


        this.index++;
        var i = this.index;
        this.installment.key = i;
        this.installment.Number = i;
        this.installment.Amount = 0;
        this.installment.Percentage = 0;
        this.installment.AmountReadOnly = this.installmentPercentOrAmount == 'Amount' ? false : true;
        this.installment.PercentageReadOnly = this.installmentPercentOrAmount == 'Percentage' ? false : true;

        if (this.newInstallmentList.length > 0) {
            this.newInstallmentList.push(JSON.parse(JSON.stringify(this.installment)));
            var arr = this.array_move(this.newInstallmentList, this.index - 1, key);
            console.log(arr);
        } else {
            this.installmentList.push(JSON.parse(JSON.stringify(this.installment)));
            var arr = this.array_move(this.installmentList, this.index - 1, key);
            console.log(arr);
        }



    }

    removeRow(event) {
        this.isLoaded = true;
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;

        if (this.newInstallmentList.length > 0) {

            if (this.newInstallmentList.length > 1) {
                this.newInstallmentList.splice(key, 1);

                this.totalPercentage = 0;
                this.totalAmount = 0;
                this.newInstallmentList.forEach(element => {
                    if (element.key > key) {
                        element.Number--;
                        element.key--;
                    }
                    this.totalPercentage = this.totalPercentage + parseFloat(element.Percentage);
                    this.totalAmount = this.totalAmount + parseFloat(element.Amount);
                });
                this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
                this.index--;
                this.isLoaded = false;
            } else if (this.newInstallmentList.length == 1) {
                this.newInstallmentList = [];
                this.index = 0;
                this.isLoaded = false;
            }

        } else {
            console.log(this.installmentList);
            if (this.installmentList.length > 1) {
                this.installmentList.splice(key, 1);

                this.totalPercentage = 0;
                this.totalAmount = 0;
                this.installmentList.forEach(element => {
                    if (element.key > key) {
                        element.Number--;
                        element.key--;
                    }
                    this.totalPercentage = this.totalPercentage + parseFloat(element.Percentage);
                    this.totalAmount = this.totalAmount + parseFloat(element.Amount);
                });
                this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
                this.index--;
                this.isLoaded = false;
            } else if (this.installmentList.length == 1) {
                this.installmentList = [];
                this.index = 0;
                this.isLoaded = false;
            }
            console.log(this.installmentList);

        }
    }

    removeRowByKey(key) {
        this.isLoaded = true;

        if (this.newInstallmentList.length > 0) {

            if (this.newInstallmentList.length > 1) {
                this.newInstallmentList.splice(key, 1);

                this.totalPercentage = 0;
                this.totalAmount = 0;
                this.newInstallmentList.forEach(element => {
                    if (element.key > key) {
                        element.Number--;
                        element.key--;
                    }
                    this.totalPercentage = this.totalPercentage + parseFloat(element.Percentage);
                    this.totalAmount = this.totalAmount + parseFloat(element.Amount);
                });
                this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
                this.index--;
                this.isLoaded = false;
            } else if (this.newInstallmentList.length == 1) {
                this.newInstallmentList = [];
                this.index = 0;
                this.isLoaded = false;
            }

        } else {
            if (this.installmentList.length > 1) {
                this.installmentList.splice(key, 1);

                this.totalPercentage = 0;
                this.totalAmount = 0;
                this.installmentList.forEach(element => {
                    if (element.key > key) {
                        element.Number--;
                        element.key--;
                    }
                    this.totalPercentage = this.totalPercentage + parseFloat(element.Percentage);
                    this.totalAmount = this.totalAmount + parseFloat(element.Amount);
                });
                this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
                this.index--;
                this.isLoaded = false;
            } else if (this.installmentList.length == 1) {
                this.installmentList = [];
                this.index = 0;
                this.isLoaded = false;
            }
        }
    }

    handlePercentageChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;

        if (this.newInstallmentList.length > 0) {
            var accountVar = this.newInstallmentList[key];
            this.newInstallmentList[key].Percentage = event.target.value ? event.target.value : 0;
            this.newInstallmentList[key].Amount = parseFloat(parseFloat(event.target.value * (this.netSellingPrice / 100)).toFixed(2));

            this.totalPercentage = 0;
            this.totalAmount = 0;

            this.newInstallmentList.forEach(element => {
                this.totalAmount = this.totalAmount + parseFloat(element.Amount);
            });


            this.totalPercentage = parseFloat(parseFloat(this.totalAmount / this.netSellingPrice * 100).toFixed(2));
            this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
            if (this.totalPercentage == 100) {
                let element = this.newInstallmentList[this.newInstallmentList.length - 1];
                let elementAmount = parseFloat(element.Amount)
                element.Amount = (elementAmount + this.totalAmountPending).toFixed(2);
                this.totalAmount += this.totalAmountPending;
                this.totalAmountPending = 0;
            }
        } else {
            var accountVar = this.installmentList[key];
            this.installmentList[key].Percentage = event.target.value ? event.target.value : 0;
            this.installmentList[key].Amount = parseFloat(parseFloat(event.target.value * (this.netSellingPrice / 100)).toFixed(2));

            this.totalPercentage = 0;
            this.totalAmount = 0;

            this.installmentList.forEach(element => {
                this.totalAmount = this.totalAmount + parseFloat(element.Amount);
            });
            this.totalPercentage = parseFloat(parseFloat(this.totalAmount / this.netSellingPrice * 100).toFixed(2));
            this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
            if (this.totalPercentage == 100) {
                let element = this.installmentList[this.installmentList.length - 1];
                let elementAmount = parseFloat(element.Amount)
                element.Amount = (elementAmount + this.totalAmountPending).toFixed(2);
                this.totalAmount += this.totalAmountPending;
                this.totalAmountPending = 0;
            }
        }
    }
    handleDateChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;

        console.log(event.target.value);
        if (this.newInstallmentList.length > 0) {
            var accountVar = this.newInstallmentList[key];
            this.newInstallmentList[key].Date = event.target.value;

        } else {
            var accountVar = this.installmentList[key];
            this.installmentList[key].Date = event.target.value;
        }

        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                /*console.log(inputField);
                console.log(inputField.dataset);
                console.log(JSON.stringify(inputField.dataset));*/
                inputField.setCustomValidity('');

                if (inputField.checkValidity() && inputField.name == 'Date') {
                    if (inputField.value == '' || inputField.value == null) {

                        if (this.newInstallmentList.length > 0) {
                            if (inputField.dataset.id != this.newInstallmentList.length - 1) {
                                inputField.setCustomValidity('Complete this field.');
                            }
                        } else {
                            if (inputField.dataset.id != this.installmentList.length - 1) {
                                inputField.setCustomValidity('Complete this field.');
                            }
                        }
                    } else {

                        if (this.newInstallmentList.length > 0) {
                            if (inputField.dataset.id != this.newInstallmentList.length - 1 && inputField.dataset.id != 0 && this.newInstallmentList[inputField.dataset.id].Date < this.newInstallmentList[inputField.dataset.id - 1].Date) {
                                inputField.setCustomValidity('Installment Date should be more than previous installment');
                            }
                        } else {
                            console.log(this.installmentList[inputField.dataset.id]);
                            console.log(this.installmentList[inputField.dataset.id - 1]);
                            if (inputField.dataset.id != this.installmentList.length - 1 && inputField.dataset.id != 0 && this.installmentList[inputField.dataset.id].Date < this.installmentList[inputField.dataset.id - 1].Date) {
                                inputField.setCustomValidity('Installment Date should be more than previous installment');
                            }
                        }

                    }
                }

                inputField.reportValidity();


                return validSoFar && inputField.checkValidity();
            }, true);

    }


    handleDescriptionChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;

        console.log(event.target.value);
        if (this.newInstallmentList.length > 0) {
            var accountVar = this.newInstallmentList[key];
            this.newInstallmentList[key].Description = event.target.value;

        } else {
            var accountVar = this.installmentList[key];
            this.installmentList[key].Description = event.target.value;
        }
    }


    handleAmountChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;

        if (this.newInstallmentList.length > 0) {
            var accountVar = this.newInstallmentList[key];
            this.newInstallmentList[key].Amount = event.target.value ? event.target.value : 0;
            this.newInstallmentList[key].Percentage = parseFloat(parseFloat(this.newInstallmentList[key].Amount / this.netSellingPrice * 100).toFixed(2));

            this.totalAmount = 0;
            this.totalPercentage = 0;

            this.newInstallmentList.forEach(element => {
                this.totalAmount = parseFloat((this.totalAmount + parseFloat(element.Amount)).toFixed(2));
                element.Amount = parseFloat(parseFloat(element.Amount).toFixed(2));
                element.Percentage = parseFloat(parseFloat(element.Percentage).toFixed(2));

                this.totalPercentage = this.totalPercentage + parseFloat(parseFloat(element.Percentage).toFixed(2));
            });
            this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
            if (this.totalAmountPending == 0) {
                let element = this.newInstallmentList[this.newInstallmentList.length - 1];
                element.Percentage = (element.Percentage + parseFloat((100 - this.totalPercentage))).toFixed(2);
                this.totalPercentage = 100;
            }

        } else {

            var accountVar = this.installmentList[key];
            this.installmentList[key].Amount = event.target.value ? event.target.value : 0;
            this.installmentList[key].Percentage = parseFloat(parseFloat(this.installmentList[key].Amount / this.netSellingPrice * 100).toFixed(2));

            this.totalAmount = 0;
            this.totalPercentage = 0;

            this.installmentList.forEach(element => {
                this.totalAmount = parseFloat((this.totalAmount + parseFloat(element.Amount)).toFixed(2));
                element.Amount = parseFloat(parseFloat(element.Amount).toFixed(2));
                element.Percentage = parseFloat(parseFloat(element.Percentage).toFixed(2));

                this.totalPercentage = this.totalPercentage + parseFloat(parseFloat(element.Percentage).toFixed(2));
            });
            this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));

            if (this.totalAmountPending == 0) {
                this.totalPercentage = parseFloat((this.totalAmount / this.netSellingPrice * 100).toFixed(2));
            }

            if (this.totalAmountPending == 0) {
                let element = this.installmentList[this.installmentList.length - 1];
                element.Percentage = (element.Percentage + parseFloat((100 - this.totalPercentage))).toFixed(2);
                this.totalPercentage = 100;
            }
        }

    }
    handleDiscountRebateChange(event) {
        if (event.target.name == 'discountPercentageField' || event.target.name == 'discountAmountField') {

            if (event.target.name == 'discountPercentageField') {
                this.discountPercentage = event.target.value ? event.target.value : 0;
                this.discountAmount = this.discountPercentage != 0 ? parseFloat(this.sellingPrice * (this.discountPercentage / 100)) : 0;

            } else {
                this.discountAmount = event.target.value ? event.target.value : 0;
                this.discountPercentage = this.discountAmount != 0 ? parseFloat(this.discountAmount / this.sellingPrice * 100) : 0;
            }
            this.netSellingPrice = parseFloat(this.sellingPrice - this.discountAmount);

            this.totalPercentage = 0;
            this.totalAmount = 0;
            if (this.newInstallmentList.length > 0) {
                console.log(this.newInstallmentList);
                this.newInstallmentList.forEach(element => {
                    //element.Percentage = parseFloat(parseFloat(element.Amount / this.netSellingPrice * 100).toFixed(2));

                    if (!element.readonly) {
                        element.Amount = parseFloat((element.Percentage * this.netSellingPrice / 100).toFixed(2));
                    }

                });

                this.totalAmount = 0;
                this.totalPercentage = 0;

                this.newInstallmentList.forEach(element => {
                    this.totalAmount = parseFloat((this.totalAmount + parseFloat(element.Amount)).toFixed(2));
                    element.Amount = parseFloat(parseFloat(element.Amount).toFixed(2));
                    element.Percentage = parseFloat(parseFloat(element.Percentage).toFixed(2));

                    this.totalPercentage = this.totalPercentage + parseFloat(parseFloat(element.Percentage).toFixed(2));
                });
                this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));

                if (this.totalAmountPending != 0) {
                    this.newInstallmentList[this.newInstallmentList.length - 1].Amount += parseFloat((this.totalAmountPending).toFixed(2));
                    this.totalAmount = this.totalAmount + this.totalAmountPending;
                    this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
                }
                if (this.totalPercentage != 100) {
                    this.newInstallmentList[this.newInstallmentList.length - 1].Percentage += parseFloat((100 - this.totalPercentage).toFixed(2));
                    this.totalPercentage = this.totalPercentage + (100 - this.totalPercentage);
                }

            } else {
                console.log(this.installmentList);

                this.installmentList.forEach(element => {

                    //element.Percentage = parseFloat(parseFloat(element.Amount / this.netSellingPrice * 100).toFixed(2));

                    if (!element.readonly) {
                        element.Amount = parseFloat((element.Percentage * this.netSellingPrice / 100).toFixed(2));
                    }

                    this.totalAmount = 0;
                    this.totalPercentage = 0;


                    this.installmentList.forEach(element => {
                        this.totalAmount = parseFloat((this.totalAmount + parseFloat(element.Amount)).toFixed(2));
                        element.Amount = parseFloat(parseFloat(element.Amount).toFixed(2));
                        element.Percentage = parseFloat(parseFloat(element.Percentage).toFixed(2));

                        this.totalPercentage = this.totalPercentage + parseFloat(parseFloat(element.Percentage).toFixed(2));
                    });
                    this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));

                    if (this.totalAmountPending != 0) {
                        this.installmentList[this.installmentList.length - 1].Amount += parseFloat((this.totalAmountPending).toFixed(2));
                        this.totalAmount = this.totalAmount + this.totalAmountPending;
                        this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
                    }
                    if (this.totalPercentage != 100) {
                        this.installmentList[this.installmentList.length - 1].Percentage += parseFloat((100 - this.totalPercentage).toFixed(2));
                        this.totalPercentage = this.totalPercentage + (100 - this.totalPercentage);
                    }
                });
            }

            this.totalPercentage = parseFloat(parseFloat(this.totalAmount / this.netSellingPrice * 100).toFixed(2));
            this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));

        }

        if (event.target.name == 'rebatePercentageField' || event.target.name == 'rebateAmountField') {
            if (event.target.name == 'rebatePercentageField') {
                this.rebatePercentage = event.target.value ? event.target.value : 0;
                this.rebateAmount = this.rebatePercentage != 0 ? this.sellingPrice * (this.rebatePercentage / 100) : 0;

            } else if (event.target.name == 'rebateAmountField') {
                this.rebateAmount = event.target.value ? event.target.value : 0;
                this.rebatePercentage = this.rebateAmount != 0 ? this.rebateAmount / this.sellingPrice * 100 : 0;
            }
        }

    }

    handleDiscountByOptionChange(event) {

        if (event.target.name == 'discountBy') {
            this.discountBy = event.target.value;
            console.log(this.discountBy);

            if (this.discountBy == 'Percentage') {
                this.discountAmountReadOnly = true;
                this.discountPercentageReadOnly = false;

            } else if (this.discountBy == 'Amount') {
                this.discountAmountReadOnly = false;
                this.discountPercentageReadOnly = true;
            }

        } else if (event.target.name == 'rebateBy') {
            this.rebateBy = event.target.value;
            console.log(this.rebateBy);

            if (this.rebateBy == 'Percentage') {
                this.rebateAmountReadOnly = true;
                this.rebatePercentageReadOnly = false;

            } else if (this.rebateBy == 'Amount') {
                this.rebateAmountReadOnly = false;
                this.rebatePercentageReadOnly = true;
            }

        } else if (event.target.name == 'installmentPercentOrAmountBy') {
            this.installmentPercentOrAmount = event.target.value;
            console.log(this.installmentPercentOrAmount);



            if (this.installmentPercentOrAmount == 'Percentage') {

                if (this.newInstallmentList.length > 0) {
                    this.newInstallmentList.forEach(element => {
                        if (!element.readonly) {
                            element.AmountReadOnly = true;
                            element.PercentageReadOnly = false;
                        }
                    });
                }

                this.installmentList.forEach(element => {
                    if (!element.readonly) {
                        element.AmountReadOnly = true;
                        element.PercentageReadOnly = false;
                    }
                });

            } else if (this.installmentPercentOrAmount == 'Amount') {

                if (this.newInstallmentList.length > 0) {
                    this.newInstallmentList.forEach(element => {
                        if (!element.readonly) {
                            element.AmountReadOnly = false;
                            element.PercentageReadOnly = true;
                        }
                    });
                }

                this.installmentList.forEach(element => {
                    if (!element.readonly) {
                        element.AmountReadOnly = false;
                        element.PercentageReadOnly = true;
                    }
                });
            }
        }

    }

    handlePaymentPlanOptionChange(event) {

        this.paymentPlanChoosed = event.target.value;
        this.newInstallmentList = [];
        this.paymentInstallments = [];
        this.totalAmount = 0;
        this.totalPercentage = 0;
        this.totalAmountPending = 0;

        console.log(this.listOfPaymentPlans);

        this.index = 0;
        if (this.paymentPlanChoosed == '') {
            this.index = this.installmentList.length;

            this.installmentList.forEach(element => {
                this.totalAmount = this.totalAmount + parseFloat(element.Amount);
            });
            this.totalPercentage = (parseFloat(this.totalAmount / parseFloat(this.netSellingPrice)).toFixed(2)) * 100;
            this.totalAmountPending = parseFloat(((100 - this.totalPercentage) / 100 * this.netSellingPrice).toFixed(2));
        } else {

            this.listOfPaymentPlans.forEach(element => {

                if (element.Name == this.paymentPlanChoosed) {
                    this.paymentInstallments = [...this.paymentInstallments, element.PaymentInstallments__r];
                }
            });

            var ppInstallmentIndex = 0;
            var ppPercentage = 0;
            this.paymentInstallments[0].forEach(element => {

                var result = this.installmentList.find(item => item.Number === element.InstallmentNumber__c);
                console.log(JSON.stringify(result));

                if (result != null && result.readonly) {
                    this.newInstallmentList.push({
                        Number: result.Number,
                        Percentage: result.Percentage,
                        Date: result.Date,
                        Amount: result.Amount,
                        readonly: true,
                        key: result.key,
                        Id: result.Id,
                        PercentageReadOnly: true,
                        AmountReadOnly: true,
                        Description: element.Description__c
                    })
                    this.totalAmount = this.totalAmount + parseFloat(result.Amount);
                    ppInstallmentIndex++;

                } else {
                    this.newInstallmentList.push({
                        Number: element.InstallmentNumber__c,
                        Percentage: element.InstallmentPercentage__c,
                        Date: element.InstallmentDate__c,
                        Amount: element.InstallmentPercentage__c * parseFloat((this.netSellingPrice / 100).toFixed(2)),
                        readonly: false,
                        key: this.index,
                        PercentageReadOnly: this.installmentPercentOrAmount == 'Percentage' ? false : true,
                        AmountReadOnly: this.installmentPercentOrAmount == 'Amount' ? false : true,
                        Description: element.Description__c
                    })
                    this.totalAmount = this.totalAmount + element.InstallmentPercentage__c * parseFloat((this.netSellingPrice / 100).toFixed(2));
                }

                this.index++;
            });

            this.totalAmount = this.totalAmount.toFixed(2);
            this.totalPercentage = (parseFloat((this.totalAmount / parseFloat(this.netSellingPrice))) * 100).toFixed(2);
            this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));

            var percentageToDelete = 0;
            if (this.totalPercentage > 100) {
                this.newInstallmentList[ppInstallmentIndex].Amount = parseFloat((this.newInstallmentList[ppInstallmentIndex].Amount + this.totalAmountPending).toFixed(2));
                this.newInstallmentList[ppInstallmentIndex].Percentage = parseFloat((this.newInstallmentList[ppInstallmentIndex].Amount / this.netSellingPrice * 100).toFixed(2));
                this.totalAmountPending = parseFloat((this.totalAmountPending + this.newInstallmentList[ppInstallmentIndex].Amount).toFixed(2));;

                if (this.newInstallmentList[ppInstallmentIndex].Percentage < 0) {
                    percentageToDelete = parseFloat((this.newInstallmentList[ppInstallmentIndex].Percentage).toFixed(2));
                    this.newInstallmentList[ppInstallmentIndex].Amount = 0;
                    this.newInstallmentList[ppInstallmentIndex].Percentage = 0;

                    console.log(percentageToDelete);

                }
                if (percentageToDelete != 0) {
                    for (let index = ppInstallmentIndex + 1; index < this.newInstallmentList.length; index++) {
                        this.newInstallmentList[index].Percentage = this.newInstallmentList[index].Percentage + percentageToDelete;
                        this.newInstallmentList[index].Amount = this.netSellingPrice * (this.newInstallmentList[index].Percentage / 100);

                        this.totalAmountPending = parseFloat((this.totalAmountPending - this.newInstallmentList[index].Amount).toFixed(2));

                        if (this.newInstallmentList[index].Percentage < 0) {
                            percentageToDelete = parseFloat((this.newInstallmentList[index].Percentage).toFixed(2));
                            this.newInstallmentList[index].Amount = 0;
                            this.newInstallmentList[index].Percentage = 0;
                        } else {
                            percentageToDelete = 0;
                        }
                        console.log(percentageToDelete);

                    }
                }

                console.log(percentageToDelete);
            } else if (this.totalPercentage < 100) {

                this.addRow();
                this.newInstallmentList[this.index - 1].Percentage = 100 - (parseFloat((this.totalAmount / parseFloat(this.netSellingPrice))) * 100);
                this.newInstallmentList[this.index - 1].Amount = this.netSellingPrice - this.totalAmount;
                this.newInstallmentList[this.index - 1].readonly = false;
                this.newInstallmentList[this.index - 1].key = this.newInstallmentList.length - 1;
                this.newInstallmentList[this.index - 1].AmountReadOnly = this.installmentPercentOrAmount == 'Amount' ? false : true;
                this.newInstallmentList[this.index - 1].PercentageReadOnly = this.installmentPercentOrAmount == 'Percentage' ? false : true;

                console.log('*****newInstallmentList*****');
                console.log(JSON.stringify(this.newInstallmentList));

                this.totalAmount = 0;
                this.newInstallmentList.forEach(element => {
                    console.log('******');
                    console.log(JSON.stringify(element));
                    this.totalAmount = parseFloat((this.totalAmount + parseFloat(element.Amount)).toFixed(2));

                });
                this.totalPercentage = (parseFloat(this.totalAmount / parseFloat(this.netSellingPrice)).toFixed(2)) * 100;
                this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));

                if (this.totalAmountPending != 0) {
                    this.newInstallmentList[this.newInstallmentList.length - 1].Amount += this.totalAmountPending;
                    this.totalAmount = this.totalAmount + this.totalAmountPending;
                    this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
                }
                if (this.totalPercentage != 100) {
                    this.newInstallmentList[this.newInstallmentList.length - 1].Percentage += 100 - this.totalPercentage;
                    this.totalPercentage = this.totalPercentage + (100 - this.totalPercentage);
                }

            }

            if (this.newInstallmentList.length > this.paymentInstallments[0].length && this.newInstallmentList[this.newInstallmentList.length - 2].readonly == false) {

                console.log('222: ' + JSON.stringify(this.newInstallmentList));
                /*this.newInstallmentList[this.index - 1].Percentage = 0;
                this.newInstallmentList[this.index - 1].Amount = 0;*/

                var today = new Date();
                var todaysDate = today.getFullYear() + '-' + (today.getMonth() + 1) + '-' + today.getDate();

                this.newInstallmentList[this.index - 1].Date = todaysDate;

                console.log(todaysDate);
                console.log('222: ' + JSON.stringify(this.newInstallmentList));

                var arr = this.array_move(this.newInstallmentList, this.index - 1, ppInstallmentIndex);
                console.log('222: ' + JSON.stringify(arr));
                console.log('222: ' + JSON.stringify(this.newInstallmentList));

            }

            for (let index = 0; index < this.newInstallmentList.length; index++) {

                if (this.newInstallmentList[index].Amount == 0) {
                    console.log(JSON.stringify(this.newInstallmentList[index]));

                    this.removeRowByKey(this.newInstallmentList[index].key);
                    index--;
                }
            }

            this.totalAmount = 0;
            this.totalPercentage = 0;
            this.newInstallmentList.forEach(element => {
                this.totalAmount = parseFloat((this.totalAmount + parseFloat(element.Amount)).toFixed(2));
                element.Amount = parseFloat(parseFloat(element.Amount).toFixed(2));
                element.Percentage = parseFloat(parseFloat(element.Percentage).toFixed(2));

                this.totalPercentage = this.totalPercentage + parseFloat(parseFloat(element.Percentage).toFixed(2));
            });
            this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));

            if (this.totalAmountPending != 0) {
                this.newInstallmentList[this.newInstallmentList.length - 1].Amount += parseFloat((this.totalAmountPending).toFixed(2));
                this.totalAmount = this.totalAmount + this.totalAmountPending;
                this.totalAmountPending = parseFloat((this.netSellingPrice - this.totalAmount).toFixed(2));
            }
            if (this.totalPercentage != 100) {
                this.newInstallmentList[this.newInstallmentList.length - 1].Percentage += parseFloat((100 - this.totalPercentage).toFixed(2));
                this.totalPercentage = this.totalPercentage + (100 - this.totalPercentage);
            }

            //this.totalAmountPending = this.netSellingPrice - this.totalAmount;
            //this.totalPercentage = (parseFloat(this.totalAmount) / parseFloat(this.netSellingPrice)) * 100;

        }

        const comboboxInputsCorrect = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputField) => {

                inputField.setCustomValidity('');

                if (inputField.checkValidity() && inputField.name == 'PaymentPlanCombobox') {
                    if (this.paymentPlanOptions[0].label == '' && this.paymentPlanChoosed == '') {
                        inputField.setCustomValidity('Complete this field.');
                    }
                }
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
    }

    array_move(arr, old_index, new_index) {
        if (new_index >= arr.length) {
            var k = new_index - arr.length + 1;
            while (k--) {
                arr.push(undefined);
            }
        }
        arr.splice(new_index, 0, arr.splice(old_index, 1)[0]);

        var count = 0;
        arr.forEach(element => {
            element.key = count;
            element.Number = count + 1;
            count++;
        });

        return arr; // for testing
    };

    saveRecord() {

        console.log('paymentPlanId: ');


        this.error = { message: '' };
        this.errorMessageToDisplay = '';

        const comboboxInputsCorrect = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputField) => {

                inputField.setCustomValidity('');

                if (inputField.checkValidity() && inputField.name == 'PaymentPlanCombobox') {
                    if (this.paymentPlanOptions[0].label == '' && this.paymentPlanChoosed == '') {
                        inputField.setCustomValidity('Complete this field.');
                    }
                }
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        const descriptionInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {

                inputField.setCustomValidity('');

                if (inputField.checkValidity() && inputField.name == 'Description') {
                    if (this.newInstallmentList.length > 0) {
                        if (inputField.dataset.id != 0 && (!this.newInstallmentList[inputField.dataset.id].Description || this.newInstallmentList[inputField.dataset.id].Description == '')) {
                            inputField.setCustomValidity('Description Should not Empty');
                        }
                    } else {
                        if (inputField.dataset.id != 0 && (!this.installmentList[inputField.dataset.id].Description || this.installmentList[inputField.dataset.id].Description == '')) {
                            inputField.setCustomValidity('Description Should not Empty');
                        }
                    }
                }
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (!descriptionInputsCorrect) {
            this.showToast('Description', 'Description should not empty', 'error');
        }

        //ASF-1485(Begin) : Changes Made to have a validation check on Installment Percentage and Amount 
        const percentageInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.setCustomValidity('');

                if (inputField.checkValidity() && inputField.name == 'Percentage') {
                    if (this.newInstallmentList.length > 0) {
                        if (inputField.dataset.id != 0 && (!this.newInstallmentList[inputField.dataset.id].Percentage || this.newInstallmentList[inputField.dataset.id].Percentage <= 0)) {
                            inputField.setCustomValidity('Installment Percentage Should be more than zero');
                        }
                    } else {
                        if (inputField.dataset.id != 0 && (!this.installmentList[inputField.dataset.id].Percentage || this.installmentList[inputField.dataset.id].Percentage <= 0)) {
                            inputField.setCustomValidity('Installment Percentage Should be more than zero');
                        }
                    }
                }
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (!percentageInputsCorrect) {
            this.showToast('Installment Percentage', 'Installment Percentage Should be more than zero', 'error');
        }

        const amountInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.setCustomValidity('');

                if (inputField.checkValidity() && inputField.name == 'Amount') {
                    if (this.newInstallmentList.length > 0) {
                        if (inputField.dataset.id != 0 && (!this.newInstallmentList[inputField.dataset.id].Amount || this.newInstallmentList[inputField.dataset.id].Amount <= 0)) {
                            inputField.setCustomValidity('Installment Amount Should be more than zero');
                        }
                    } else {
                        if (inputField.dataset.id != 0 && (!this.installmentList[inputField.dataset.id].Amount || this.installmentList[inputField.dataset.id].Amount <= 0)) {
                            inputField.setCustomValidity('Installment Amount Should be more than zero');
                        }
                    }
                }
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (!amountInputsCorrect) {
            this.showToast('Installment Amount', 'Installment Amount Should be more than zero', 'error');
        }
        //ASF-1485(End) : Changes Made to have a validation check on Installment Percentage and Amount 


        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                /*console.log(inputField);
                console.log(inputField.dataset);
                console.log(JSON.stringify(inputField.dataset));*/
                inputField.setCustomValidity('');

                if (inputField.checkValidity() && inputField.name == 'Date') {
                    if (inputField.value == '' || inputField.value == null) {

                        if (this.newInstallmentList.length > 0) {
                            if (inputField.dataset.id != this.newInstallmentList.length - 1) {
                                inputField.setCustomValidity('Complete this field.');
                            }
                        } else {
                            if (inputField.dataset.id != this.installmentList.length - 1) {
                                inputField.setCustomValidity('Complete this field.');
                            }
                        }
                    } else {

                        if (this.newInstallmentList.length > 0) {
                            if (inputField.dataset.id != 0 && this.newInstallmentList[inputField.dataset.id].Date < this.newInstallmentList[inputField.dataset.id - 1].Date) {
                                inputField.setCustomValidity('Installment Date should be more than previous installment');
                            }
                        } else {
                            if (inputField.dataset.id != 0 && this.installmentList[inputField.dataset.id].Date < this.installmentList[inputField.dataset.id - 1].Date) {
                                inputField.setCustomValidity('Installment Date should be more than previous installment');
                            }
                        }

                    }
                }
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        console.log('###All Validations Passed###');
        debugger;
        var installmentListToInsert = [...this.installmentList];

        if (this.newInstallmentList.length > 0) {
            installmentListToInsert = [...this.newInstallmentList];
        }

        if (isInputsCorrect && comboboxInputsCorrect && descriptionInputsCorrect) {
            this.totalAmount = this.totalAmount.toFixed(2);
            this.netSellingPrice = this.netSellingPrice.toFixed(2);
            if (this.totalPercentage != 100) {
                this.error.message = 'Installment Percentage Should be 100%';
                this.reduceErrors(this.error);

            } else if (this.totalAmount != this.netSellingPrice) {
                this.error.message = 'Total Amount Should be Equal Net Selling Price';
                this.reduceErrors(this.error);
            } else {
                this.isLoaded = true;

                var paymentPlan = 'Easy Payment Plan';
                if (this.oldInstallmentCount != this.index + 1) {
                    paymentPlan = 'Aggressive Payment Plan';
                }

                var paymentPlanId = '';

                if (paymentPlanId == '' && this.paymentPlanOptions[0].label != '' && this.paymentPlanChoosed == '') {
                    paymentPlanId = this.srRecord.PaymentPlan__c;
                } else {
                    this.listOfPaymentPlans.forEach(element => {
                        if (this.paymentPlanChoosed == element.Name) {
                            paymentPlanId = element.Id;
                        }
                    });
                }
                console.log('paymentPlanId: ' + paymentPlanId);

                if (this.memoLineRecord != null) {
                    this.memoLineRecord.DiscountPercentage__c = this.discountPercentage;
                    this.memoLineRecord.RebatePercentage__c = this.rebatePercentage;

                    console.log(installmentListToInsert);
                    updateInstallmentChangesRecords({ memoLineRecord: this.memoLineRecord, installmentLineChangesList: installmentListToInsert, srRecord: this.srRecord, newNetSellingPrice: this.netSellingPrice, paymentPlanId: paymentPlanId }).then(result => {

                        this.navigateToSR();
                        this.isLoaded = false;
                        /*completeServiceRequestStep({ step: this.stepRecord, sr: this.srRecord }).then(result => {
                            this.navigateToSR();
                            this.isLoaded = false;
                        }).catch(error => {
                            this.error = error;
                            this.reduceErrors(error);
                            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                            this.isLoaded = false;
                        })*/

                    }).catch(error => {
                        this.error = error;
                        this.reduceErrors(error);
                        this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                        this.isLoaded = false;
                    })

                } else {
                    createBookingMemo({ srRecord: this.srRecord, discountPercentage: this.discountPercentage, rebatePercentage: this.rebatePercentage, installmentList: installmentListToInsert, paymentPlan: paymentPlan, newNetSellingPrice: this.netSellingPrice, paymentPlanId: paymentPlanId }).then(result => {

                        this.navigateToSR();
                        this.isLoaded = false;

                        /*completeServiceRequestStep({ step: this.stepRecord, sr: this.srRecord }).then(result => {
                            console.log('result>>>' + JSON.stringify(result));
                            this.navigateToSR();
                            this.isLoaded = false;
                        }).catch(error => {
                            this.error = error;
                            this.reduceErrors(error);
                            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                            console.error(this.errorMessageToDisplay);
                            console.error('error>>>' + JSON.stringify(error));
                            this.isLoaded = false;
                        })*/

                    }).catch(error => {
                        this.error = error;
                        this.reduceErrors(error);
                        this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                        this.isLoaded = false;
                    })
                }
            }
        }
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    navigateToSR() {
        this.readOnlyScreen = true;
        this.discountAmountReadOnly = true;
        this.discountPercentage = true;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'HexaBPM__Service_Request__c',
                actionName: 'view'
            }
        }).then((url) => {
            window.location.replace(url);
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant

        });
        this.dispatchEvent(event);
    }

    reduceErrors(errors) {
        if (this.error.body) {
            if (Array.isArray(this.error.body)) {
                this.errorMessageToDisplay += this.error.body.map(e => e.message).join(', ');
            }
            else if (typeof this.error.body === 'object') {
                let fieldErrors = this.error.body.fieldErrors;
                let pageErrors = this.error.body.pageErrors;
                let duplicateResults = this.error.body.duplicateResults;
                let exceptionError = this.error.body.message;

                if (exceptionError && typeof exceptionError === 'string') {
                    this.errorMessageToDisplay += exceptionError;
                }

                if (fieldErrors) {
                    for (var fieldName in fieldErrors) {
                        let errorList = fieldErrors[fieldName];
                        for (var i = 0; i < errorList.length; i++) {
                            this.errorMessageToDisplay += fieldName + ' ' + errorList[i].message + ' ';
                            this.errorHeader = pageErrors[i] != null ? pageErrors[i].statusCode : this.errorHeader;
                        }
                    }
                }

                if (pageErrors && pageErrors.length > 0) {
                    for (let i = 0; i < pageErrors.length; i++) {
                        this.errorMessageToDisplay += pageErrors[i].message;
                        this.errorHeader = pageErrors[i] != null ? pageErrors[i].statusCode : this.errorHeader;
                    }
                }

                if (duplicateResults && duplicateResults.length > 0) {
                    this.errorMessageToDisplay += 'duplicate result error';
                }
            }
        }
        // handles errors from the lightning record edit form
        if (this.error.message) {
            this.errorMessageToDisplay += this.error.message;
        }
        if (this.error.detail) {
            this.errorMessageToDisplay += this.error.detail;
        }

    }
}