export const EXAMPLES_COLUMNS_DEFINITION_BASIC = [

    {
        type: 'text',
        fieldName: 'column0',
        label: '',
        // initialWidth: 200,
        initialWidth: 10,
        cellAttributes: { class: 'column-id' }

        
    },
    {
        type: 'text',
        fieldName: 'column5',
        label: 'Customer',
        initialWidth: 120,
        cellAttributes: { class: 'rooms-cell' /*important for reponsive */ }
    },
    {
        type: 'text',
        fieldName: 'column1',
        label: 'Agency Name',
        initialWidth: 150,
        cellAttributes: { class: 'agency-name-cell' /*important for reponsive */ }
    },
    {
        type: 'text',
        fieldName: 'column2',
        label: 'Agent Name',
        initialWidth: 150,
        cellAttributes: { class: 'agent-name-cell' /*important for reponsive */ }
    },
    {
        type: 'text',
        fieldName: 'column3',
        label: 'Property',
        initialWidth: 150,
        cellAttributes: { class: 'property-cell' /*important for reponsive */ }
    },
    {
        type: 'text',
        fieldName: 'column4',
        label: 'Unit Number',
        initialWidth: 150,
        cellAttributes: { class: 'unit-number-cell' /*important for reponsive */ }
    },
    //Moved above as customer Name
    {
        type: 'number',
        fieldName: 'column6',
        initialWidth: 150,
        label: 'Net Price',
        cellAttributes: { class: 'net-price-cell' /*important for reponsive */ }
    },
    {
        type: 'date',
        fieldName: 'column7',
        initialWidth: 150,
        label: 'Order Date',
        cellAttributes: { class: 'order-date-cell' /*important for reponsive */ }
    },
    {
        type: 'number',
        fieldName: 'column8',
        initialWidth: 150,
        label: 'Commission',
        cellAttributes: { class: 'commission-cell' /*important for reponsive */ }
    },
    {
        type: 'percent',
        typeAttributes: {
            minimumFractionDigits: '2',
            maximumFractionDigits: '5',
        },
        fieldName: 'column9',
        label: 'Rate',
        initialWidth: 100,
        cellAttributes: { class: 'rate-cell' /*important for reponsive */ }
    },
    {
        label: 'Sales Order Status',
        fieldName: 'column14',
        type: 'text',
        initialWidth: 150,
        cellAttributes: { class: 'sales-order-status' /*important for reponsive */ }
    },
    {
        label: 'Status',
        initialWidth: 150,
        fieldName: 'column10',
        type: 'percent',
        cellAttributes: {
            iconName: { fieldName: 'statusIcon' },
            iconPosition: 'left',
        }

    },
    /*{
        type: 'text',
        fieldName: 'column11',
        label: 'Agent Type',
        cellAttributes: { class: 'agent-type-cell' /* important for reponsive * / }
    },*/
    {

        label: 'Action',
        fieldName: 'column12',
        type: 'button',
        initialWidth: 60,
        typeAttributes: {
            iconName: 'utility:edit',

            name: 'View',
            title: 'editTitle',
            disabled: false,
            value: 'test'

        },
        cellAttributes: {
            class: 'custom-grid-icon file-icon ',
            alignment: `left`
        }
    },
    {

        label: '',
        fieldName: 'column13',
        initialWidth: 60,
        type: 'button',
        typeAttributes: {
            iconName: 'utility:edit',

            name: 'Expand',
            title: 'editTitle',
            disabled: false,
            value: 'test'

        },
        cellAttributes: {
            class: 'custom-grid-icon collapse-icons',
            alignment: `left`
        }
    }
];


export const EXAMPLES_DATA_BASIC = [
    {
        // agencyName:"agencyName",
        // agentName: "Rola Zayat",
        // property: "Al Ghadeer - R1",
        // unitNumber: "Al Ghadeer - R1",
        // rooms: "1 BHK",
        // netPrice: "44.55k",
        // orderDate: "11-12-21",
        // commission: "44.55k",
        // rate: "2.5",
        // status: "",
        // statusIcon: 'utility:clock',
        // agentType: "External",
        column0: 1,
        column1: "agencyName",
        column2: "Rola Zayat",
        column3: "Al Ghadeer - R1",
        column4: "Al Ghadeer - R1",
        column5: "1 BHK",
        column6: "44.55k",
        column7: "11-12-21",
        column8: "44.55k",
        column9: "2.5",
        column10: "",
        statusIcon: 'utility:ban',
        column11: "External",
        column12: "",
        column13: "",
        _children: [
            {
                column0: 1.1,
                column1: 'Paid Amount:',
                column2: '',
                column3: "Invoice #:",
                column4: "2",
                column5: '',
                column6: '',
                column7: 'Paid Flag: -',
                column8: "44.55k",
                column9: "2.5",
                column10: "",
               
                column11: "Cleared Date: Cleared Date:",
                column12: "",
                column13: "",
            },
            {
                column0: 1.2,
                column1: 'Invoice Date:  Invoice Date:',
                column2: '',
                column3: "Payment Due Date:",
                column4: "22/01/2022",
                column5: '',
                column6: '',
                column7: 'Paid Flag: -',
                column8: "44.55k",
                column9: "2.5",
                column10: "",
                
                column11: "Cleared Date: Cleared Date:",
                column12: "",
                column13: "",

            }
        ]
    },
    {
        // agencyName:"agencyName",
        // agentName: "Rola Zayat",
        // property: "Al Ghadeer - R1",
        // unitNumber: "Al Ghadeer - R1",
        // rooms: "1 BHK",
        // netPrice: "44.55k",
        // orderDate: "11-12-21",
        // commission: "44.55k",
        // rate: "2.5",
        // status: "",
        // statusIcon: 'utility:clock',
        // agentType: "External",
        column0: 2,
        column1: "agencyName",
        column2: "Rola Zayat",
        column3: "Al Ghadeer - R1",
        column4: "Al Ghadeer - R1",
        column5: "1 BHK",
        column6: "44.55k",
        column7: "11-12-21",
        column8: "44.55k",
        column9: "2.5",
        column10: "",
        statusIcon: 'utility:ban',
        column11: "External",
        column12: "",
        column13: "",
        _children: [
            {
                column0: 2.1,
                column1: 'Paid Amount:',
                column2: '',
                column3: "Invoice #:",
                column4: "2",
                column5: '',
                column6: '',
                column7: 'Paid Flag: -',
                column8: "44.55k",
                column9: "2.5",
                column10: "",
               
                column11: "Cleared Date: Cleared Date:",
                column12: "",
                column13: "",
            },
            {
                column0: 2.2,
                column1: 'Invoice Date:  Invoice Date:',
                column2: '',
                column3: "Payment Due Date:",
                column4: "22/01/2022",
                column5: '',
                column6: '',
                column7: 'Paid Flag: -',
                column8: "44.55k",
                column9: "2.5",
                column10: "",
                
                column11: "Cleared Date: Cleared Date:",
                column12: "",
                column13: "",

            }
        ]
    }
    /*
    ,
    {
        agencyName:"agencyName",
        agentName: "Evgeny Ratskevich",
        property: "Al Ghadeer - R1",
        unitNumber: "Al Ghadeer - R1",
        rooms: "1 BHK",
        netPrice: "625.11k",
        orderDate: "11-12-21",
        commission: "625.11k",
        rate: "3.5",
        status: "",
        statusIcon: 'utility:clock',
        agentType:"External",
        column7:"",
        column8: ""
    },
    {
        agencyName:"agencyName",
        agentName: "Natalia Kushparneko",
        property: "Al Ghadeer - R1",
        unitNumber: "Al Ghadeer - R1",
        rooms: "3 BHK",
        netPrice: "715.61k",
        orderDate: "19-11-21",
        commission: "715.61k",
        rate: "3.5",
        status: "",
        statusIcon: 'utility:clock',
        agentType:"External",
        column7:"",
        column8: ""
    },
    {
        agencyName:"agencyName",
        agentName: "Takla Gal",
        property: "Takla Gal",
        unitNumber: "Al Ghadeer - R1",
        rooms: "2 BHK",
        netPrice: "921.42k",
        orderDate: "14-11-21",
        commission: "921.42k",
        rate: "2.5",
        status: "",
        statusIcon: 'utility:internal_share',
        agentType:"External",
        column7:"",
        column8: ""
    }, {
        agencyName:"agencyName",
        agentName: "Evgeny Ratskevich",
        property: "Mamsha",
        unitNumber: "Mamsha",
        rooms: "2 BHK",
        netPrice: "301.60k",
        orderDate: "23-10-21",
        commission: "301.60k",
        rate: "5.0",
        status: "",
        statusIcon: 'utility:internal_share',
        agentType:"External",
        column7:"",
        column8: ""
    }, {
        agencyName:"agencyName",
        agentName: "Rola Zayat",
        property: "Mamsha",
        unitNumber: "Mamsha",
        rooms: "1 BHK",
        netPrice: "211.11k",
        orderDate: "09-11-21",
        commission: "211.11k",
        rate: "2.5",
        status: "",
        statusIcon: 'utility:internal_share',
        agentType:"External",
        column7:"",
        column8: ""
    }, {
        agencyName:"agencyName",
        agentName: "Natalia Kushparneko",
        property: "YasAcres The Dahlias",
        unitNumber: "YasAcres The Dahlias",
        rooms: "2 BHK",
        netPrice: "222.42k",
        orderDate: "14-10-21",
        commission: "222.42k",
        rate: "222.42k",
        status: "",
        statusIcon: 'utility:contract_payment',
        agentType:"External",
        column7:"",
        column8: ""
    }, {
        agencyName:"agencyName",
        agentName: "Takla Gal",
        property: "YasAcres The Dahlias",
        unitNumber: "YasAcres The Dahlias",
        rooms: "3 BHK",
        netPrice: "555.99k",
        orderDate: "01-10-21",
        commission: "555.99k",
        rate: "2.5",
        status: "",
        statusIcon: 'utility:ban',
        agentType:"External",
        column7:"",
        column8: ""
    } */



    // _children: [
    //     {
    // column1: 'Project: Mamsha1',
    // column2: '',
    // column3: "Unity Type: 2BHK",
    // column4: "",
    // column5: 'Created Date & Time: 15.30-22/01/2022',
    // column6: 'Promotion: Q4 Summer Promo Summer 2021',
    // column7:111

    //     },

    //     {
    // column1: 'Project: Mayan1',
    // column2: '',
    // column3: "Unity Type: 2BHK + M",
    // column4: "",
    // column5: 'Created Date & Time: 15.00-22/01/2022',
    // column6: 'Promotion: Q4 Summer Promo Summer 2021',
    // column7:222

    //     }, {
    //         column1: 'Project: Mayan1',
    //         column2: '',
    //         column3: "Unity Type: 2BHK + M",
    //         column4: "",
    //         column5: 'Created Date & Time: 15.00-22/01/2022',
    //         column6: 'Promotion: Q4 Summer Promo Summer 2021',
    //         column7:999

    //             }, {
    //                 column1: 'Project: Mayan1',
    //                 column2: '',
    //                 column3: "Unity Type: 2BHK + M",
    //                 column4: "",
    //                 column5: 'Created Date & Time: 15.00-22/01/2022',
    //                 column6: 'Promotion: Q4 Summer Promo Summer 2021',
    //                 column7:101010

    //                     }
    // ],

];