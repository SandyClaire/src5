/*
 * Copyright Cypress Semiconductor Corporation, 2014-2015 All rights reserved.
 *
 * This software, associated documentation and materials ("Software") is
 * owned by Cypress Semiconductor Corporation ("Cypress") and is
 * protected by and subject to worldwide patent protection (UnitedStates and foreign), United States copyright laws and international
 * treaty provisions. Therefore, unless otherwise specified in a separate license agreement between you and Cypress, this Software
 * must be treated like any other copyrighted material. Reproduction,
 * modification, translation, compilation, or representation of this
 * Software in any other form (e.g., paper, magnetic, optical, silicon)
 * is prohibited without Cypress's express written permission.
 *
 * Disclaimer: THIS SOFTWARE IS PROVIDED AS-IS, WITH NO WARRANTY OF ANY
 * KIND, EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
 * NONINFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE. Cypress reserves the right to make changes
 * to the Software without notice. Cypress does not assume any liability
 * arising out of the application or use of Software or any product or
 * circuit described in the Software. Cypress does not authorize its
 * products for use as critical components in any products where a
 * malfunction or failure may reasonably be expected to result in
 * significant injury or death ("High Risk Product"). By including
 * Cypress's product in a High Risk Product, the manufacturer of such
 * system or application assumes all risk of such use and in doing so
 * indemnifies Cypress against all liability.
 *
 * Use of this Software may be limited by and subject to the applicable
 * Cypress software license agreement.
 *
 *
 */
package com.cypress.cysmart1.ListAdapters;

import android.bluetooth.BluetoothGattDescriptor;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

import com.cypress.cysmart1.CommonUtils.GattAttributes;
import com.cypress.cysmart1.CommonUtils.LogUtil;
import com.cypress.cysmart1.R;

import java.util.List;

/**
 * Adapter class for listing the GATT Characteristics
 */
public class GattCharacteristicDescriptorsAdapter extends BaseAdapter {
    /**
     * BluetoothGattCharacteristic list
     */
    private List<BluetoothGattDescriptor> mGattCharacteristics;

    private Context mContext;

    public GattCharacteristicDescriptorsAdapter(Context mContext,
                                                List<BluetoothGattDescriptor> list) {
		LogUtil.e("GattCharacteristicDescriptorsAdapter", "GattCharacteristicDescriptorsAdapter()");
        this.mContext = mContext;
        this.mGattCharacteristics = list;
    }

    @Override
    public int getCount() {
		LogUtil.e("GattCharacteristicDescriptorsAdapter", "getCount()");
        return mGattCharacteristics.size();
    }

    @Override
    public Object getItem(int i) {
		LogUtil.e("GattCharacteristicDescriptorsAdapter", "getItem()");
        return mGattCharacteristics.get(i);
    }

    @Override
    public long getItemId(int i) {
		LogUtil.e("GattCharacteristicDescriptorsAdapter", "getItemId()");
        return i;
    }

    @Override
    public View getView(int i, View view, ViewGroup viewGroup) {
		LogUtil.e("GattCharacteristicDescriptorsAdapter", "getView()");
        ViewHolder viewHolder;
        // General ListView optimization code.
        if (view == null) {
            LayoutInflater mInflator = (LayoutInflater) mContext
                    .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            view = mInflator.inflate(R.layout.gattdb_characteristics_list_item,
                    viewGroup, false);
            viewHolder = new ViewHolder();
            viewHolder.serviceName = (TextView) view
                    .findViewById(R.id.txtservicename);
            viewHolder.propertyName = (TextView) view
                    .findViewById(R.id.txtstatus);
            viewHolder.parameter = (TextView) view
                    .findViewById(R.id.parameter);
            view.setTag(viewHolder);
        } else {
            viewHolder = (ViewHolder) view.getTag();
        }
        viewHolder.serviceName.setSelected(true);
        BluetoothGattDescriptor item = mGattCharacteristics.get(i);
        String name = GattAttributes.lookupUUID(item.getUuid(), item
                .getUuid().toString());
        viewHolder.serviceName.setText(name);
        viewHolder.propertyName.setText("" + item.getUuid().toString());
        viewHolder.parameter.setText("UUID :");

        return view;
    }

    /**
     * Holder class for the ListView variable
     */
    class ViewHolder {
        TextView serviceName, propertyName, parameter;

    }

}

