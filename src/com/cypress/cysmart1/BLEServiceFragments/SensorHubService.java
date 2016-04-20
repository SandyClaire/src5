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
package com.cypress.cysmart1.BLEServiceFragments;

import android.app.ProgressDialog;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.util.DisplayMetrics;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

import com.cypress.cysmart1.BLEConnectionServices.BluetoothLeService;
import com.cypress.cysmart1.CommonUtils.Constants;
import com.cypress.cysmart1.CommonUtils.CustomSlideAnimation;
import com.cypress.cysmart1.CommonUtils.GattAttributes;
import com.cypress.cysmart1.CommonUtils.LogUtil;
import com.cypress.cysmart1.CommonUtils.Logger;
import com.cypress.cysmart1.CommonUtils.UUIDDatabase;
import com.cypress.cysmart1.CommonUtils.Utils;
import com.cypress.cysmart1.R;

import org.achartengine.ChartFactory;
import org.achartengine.GraphicalView;
import org.achartengine.chart.PointStyle;
import org.achartengine.model.XYMultipleSeriesDataset;
import org.achartengine.model.XYSeries;
import org.achartengine.renderer.XYMultipleSeriesRenderer;
import org.achartengine.renderer.XYSeriesRenderer;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * Fragment to display the sensor hub service
 */
public class SensorHubService extends Fragment {

    // GATT service and characteristics
    private static BluetoothGattService mCurrentservice;
    private static BluetoothGattService mAccservice;
    public static BluetoothGattService mStempservice;
    public static BluetoothGattService mSpressureservice;
    private static ArrayList<HashMap<String, BluetoothGattService>> mExtraservice;
    private static BluetoothGattCharacteristic mNotifyACCXCharacteristic;
    private static BluetoothGattCharacteristic mNotifyACCYCharacteristic;
    private static BluetoothGattCharacteristic mNotifyACCZCharacteristic;
    private static BluetoothGattCharacteristic mNotifyBATCharacteristic;
    private static BluetoothGattCharacteristic mNotifySTEMPCharacteristic;
    private static BluetoothGattCharacteristic mIndicateSPRESSURECharacteristic;
    private static BluetoothGattCharacteristic mWriteAlertCharacteristic;
    private static BluetoothGattCharacteristic mReadACCXCharacteristic;
    private static BluetoothGattCharacteristic mReadACCYCharacteristic;
    private static BluetoothGattCharacteristic mReadACCZCharacteristic;
    private static BluetoothGattCharacteristic mReadBATCharacteristic;
    private static BluetoothGattCharacteristic mReadSTEMPCharacteristic;
    private static BluetoothGattCharacteristic mReadSPRESSURECharacteristic;
    private static BluetoothGattCharacteristic mReadACCSensorScanCharacteristic;
    private String ACCSensorScanCharacteristic = "";
    private static BluetoothGattCharacteristic mReadACCSensorTypeCharacteristic;
    private String ACCSensorTypeCharacteristic = "";
    private static BluetoothGattCharacteristic mReadACCFilterConfigurationCharacteristic;
    private static BluetoothGattCharacteristic mReadSTEMPSensorScanCharacteristic;
    private String STEMPSensorScanCharacteristic = "";
    private static BluetoothGattCharacteristic mReadSTEMPSensorTypeCharacteristic;
    private String STEMPSensorTypeCharacteristic = "";
    private static BluetoothGattCharacteristic mReadSPRESSURESensorScanCharacteristic;
    private String SPRESSURESensorScanCharacteristic = "";
    private static BluetoothGattCharacteristic mReadSPRESSURESensorTypeCharacteristic;
    private String SPRESSURESensorTypeCharacteristic = "";
    private static BluetoothGattCharacteristic mReadSPRESSUREFilterConfigurationCharacteristic;
    private static BluetoothGattCharacteristic mReadSPRESSUREThresholdCharacteristic;
    private String SPRESSUREThresholdCharacteristic = "";

    // Immediate alert constants
    private static final String IMM_NO_ALERT = "0x00";
    private static final String IMM_HIGH_ALERT = "0x02";

    private TextView mAccX;
    private TextView mAccY;
    private TextView mAccZ;
    private TextView mBattery;
    private TextView mSensorTemp;
    private TextView mSensorPressure;
    private EditText mAccScanInterval;
    private EditText mStempScanInterval;
    private TextView mAccSensortype;
    private TextView mStempSensortype;
    private EditText mSpressureScanInterval;
    private TextView mSpressureSensortype;
    private EditText mSpressureThresholdValue;
    private boolean mAccNotifySet = false;

    //ProgressDialog
    private ProgressDialog mProgressDialog;

    //Graph accelerometer
    private LinearLayout mACCGraphLayoutParent;
    private double mACCXGraphLastXValue = 0;
    private double mACCYGraphLastXValue = 0;
    private double mACCZGraphLastXValue = 0;
    private GraphicalView mAccelerometerChart;
    private XYSeries mAccXDataSeries;
    private XYSeries mAccYDataSeries;
    private XYSeries mAccZDataSeries;

    //Graph temperature
    private LinearLayout mTemperatureGraphLayoutParent;
    private double mSTempGraphLastXValue = 0;
    private GraphicalView mTemperaturerChart;
    private XYSeries mTemperatureDataSeries;

    //Graph pressure
    private LinearLayout mPressureGraphLayoutParent;
    private GraphicalView mPressureChart;
    private double mSPressureGraphLastXValue = 0;
    private XYSeries mPressureDataSeries;

    private boolean mHandlerFlag = true;

    //Constants
    private int mHeight = 200;
    private static  final int HANDLER_DELAY = 1000;
    private static  final int ROTATION_90 = 90;
    private static  final int ROTATION_N90 = -90;

    /**
     * BroadcastReceiver for receiving the GATT server status
     */
    private BroadcastReceiver mGattUpdateReceiver = new BroadcastReceiver() {

        @Override
        public void onReceive(Context context, Intent intent) {
            LogUtil.e("SensorHubService", "mGattUpdateReceiver  onReceive()");
            final String action = intent.getAction();
            Bundle extras = intent.getExtras();
            // GATT Data Available
            if (BluetoothLeService.ACTION_DATA_AVAILABLE.equals(action)) {
                if (extras.containsKey(Constants.EXTRA_ACCX_VALUE)) {
                    int received_acc_x = extras
                            .getInt(Constants.EXTRA_ACCX_VALUE);
                    displayXData("" + received_acc_x);
                    if (mReadACCYCharacteristic != null) {
                        prepareBroadcastDataRead(mReadACCYCharacteristic);
                    }

                }
                if (extras.containsKey(Constants.EXTRA_ACCY_VALUE)) {
                    int received_acc_y = extras
                            .getInt(Constants.EXTRA_ACCY_VALUE);
                    displayYData("" + received_acc_y);
                    if (mReadACCZCharacteristic != null) {
                        prepareBroadcastDataRead(mReadACCZCharacteristic);
                    }

                }
                if (extras.containsKey(Constants.EXTRA_ACCZ_VALUE)) {
                    int received_acc_z = extras
                            .getInt(Constants.EXTRA_ACCZ_VALUE);
                    displayZData("" + received_acc_z);
                    prepareBroadcastDataRead(mReadBATCharacteristic);

                }
                if (extras.containsKey(Constants.EXTRA_BTL_VALUE)) {
                    String received_bat = extras
                            .getString(Constants.EXTRA_BTL_VALUE);
                    displayBATData(received_bat);
                    prepareBroadcastDataRead(mReadSTEMPCharacteristic);
                }
                if (extras.containsKey(Constants.EXTRA_STEMP_VALUE)) {
                    float received_stemp = extras
                            .getFloat(Constants.EXTRA_STEMP_VALUE);
                    displaySTEMPData("" + received_stemp);
                    prepareBroadcastDataRead(mReadSPRESSURECharacteristic);
                }
                if (extras.containsKey(Constants.EXTRA_SPRESSURE_VALUE)) {
                    int received_spressure = extras
                            .getInt(Constants.EXTRA_SPRESSURE_VALUE);

                    displaySPressureData("" + received_spressure);
                    if (mReadACCSensorScanCharacteristic != null) {
                        prepareBroadcastDataRead(mReadACCSensorScanCharacteristic);
                    }

                }
                if (extras.containsKey(Constants.EXTRA_ACC_SENSOR_SCAN_VALUE)) {
                    int received_acc_scan_interval = extras
                            .getInt(Constants.EXTRA_ACC_SENSOR_SCAN_VALUE);
                    ACCSensorScanCharacteristic = ""
                            + received_acc_scan_interval;

                    if (mReadACCSensorTypeCharacteristic != null) {
                        prepareBroadcastDataRead(mReadACCSensorTypeCharacteristic);
                    }

                }
                if (extras.containsKey(Constants.EXTRA_ACC_SENSOR_TYPE_VALUE)) {
                    int received_acc_type = extras
                            .getInt(Constants.EXTRA_ACC_SENSOR_TYPE_VALUE);
                    ACCSensorTypeCharacteristic = "" + received_acc_type;

                    if (mReadSTEMPSensorScanCharacteristic != null) {
                        prepareBroadcastDataRead(mReadSTEMPSensorScanCharacteristic);
                    }
                }
                if (extras.containsKey(Constants.EXTRA_STEMP_SENSOR_SCAN_VALUE)) {
                    int received_stemp_scan_interval = extras
                            .getInt(Constants.EXTRA_STEMP_SENSOR_SCAN_VALUE);
                    STEMPSensorScanCharacteristic = ""
                            + received_stemp_scan_interval;
                    Logger.w("sensor scan notified");
                    if (mReadSTEMPSensorTypeCharacteristic != null) {
                        prepareBroadcastDataRead(mReadSTEMPSensorTypeCharacteristic);
                    }

                }
                if (extras.containsKey(Constants.EXTRA_STEMP_SENSOR_TYPE_VALUE)) {
                    int received_stemp_type = extras
                            .getInt(Constants.EXTRA_STEMP_SENSOR_TYPE_VALUE);
                    STEMPSensorTypeCharacteristic = "" + received_stemp_type;
                    if (mReadSPRESSURESensorScanCharacteristic != null) {
                        prepareBroadcastDataRead(mReadSPRESSURESensorScanCharacteristic);
                    }

                }
                if (extras
                        .containsKey(Constants.EXTRA_SPRESSURE_SENSOR_SCAN_VALUE)) {
                    int received_pressure_scan_interval = extras
                            .getInt(Constants.EXTRA_SPRESSURE_SENSOR_SCAN_VALUE);
                    SPRESSURESensorScanCharacteristic = ""
                            + received_pressure_scan_interval;
                    if (mReadSPRESSURESensorTypeCharacteristic != null) {
                        prepareBroadcastDataRead(mReadSPRESSURESensorTypeCharacteristic);
                    }

                }
                if (extras
                        .containsKey(Constants.EXTRA_SPRESSURE_SENSOR_TYPE_VALUE)) {
                    int received_pressure_sensor = extras
                            .getInt(Constants.EXTRA_SPRESSURE_SENSOR_TYPE_VALUE);
                    SPRESSURESensorTypeCharacteristic = ""
                            + received_pressure_sensor;
                    if (mReadSPRESSUREThresholdCharacteristic != null) {
                        prepareBroadcastDataRead(mReadSPRESSUREThresholdCharacteristic);
                    }

                }
                if (extras
                        .containsKey(Constants.EXTRA_SPRESSURE_THRESHOLD_VALUE)) {
                    int received_threshold_value = extras
                            .getInt(Constants.EXTRA_SPRESSURE_THRESHOLD_VALUE);
                    SPRESSUREThresholdCharacteristic = ""
                            + received_threshold_value;
                    if (!mAccNotifySet) {
                        mAccNotifySet = true;
                        prepareBroadcastDataNotify(mNotifyACCXCharacteristic);
                        prepareBroadcastDataNotify(mNotifyACCYCharacteristic);
                        prepareBroadcastDataNotify(mNotifyACCZCharacteristic);
                        prepareBroadcastDataNotify(mNotifyBATCharacteristic);
                        prepareBroadcastDataNotify(mNotifySTEMPCharacteristic);
                        prepareBroadcastDataIndicate(mIndicateSPRESSURECharacteristic);
                    }
                }
            }
            if (action.equals(BluetoothDevice.ACTION_BOND_STATE_CHANGED)) {
                final int state = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.ERROR);

                if (state == BluetoothDevice.BOND_BONDING) {
                    // Bonding...
                    Logger.i("Bonding is in process....");
                    Utils.bondingProgressDialog(getActivity(), mProgressDialog, true);
                } else if (state == BluetoothDevice.BOND_BONDED) {
                    String dataLog = getResources().getString(R.string.dl_commaseparator)
                            + "[" + BluetoothLeService.getmBluetoothDeviceName() + "|"
                            + BluetoothLeService.getmBluetoothDeviceAddress() + "]" +
                            getResources().getString(R.string.dl_commaseparator) +
                            getResources().getString(R.string.dl_connection_paired);
                    Logger.datalog(dataLog);
                    Utils.bondingProgressDialog(getActivity(), mProgressDialog, false);
                    getGattData();

                } else if (state == BluetoothDevice.BOND_NONE) {
                    String dataLog = getResources().getString(R.string.dl_commaseparator)
                            + "[" + BluetoothLeService.getmBluetoothDeviceName() + "|"
                            + BluetoothLeService.getmBluetoothDeviceAddress() + "]" +
                            getResources().getString(R.string.dl_commaseparator) +
                            getResources().getString(R.string.dl_connection_unpaired);
                    Logger.datalog(dataLog);
                    Utils.bondingProgressDialog(getActivity(), mProgressDialog, false);
                }
            }
        }
    };

    public SensorHubService create(
            BluetoothGattService service,
            ArrayList<HashMap<String, BluetoothGattService>> gattExtraServiceData) {
        LogUtil.e("SensorHubService", "create()");
        SensorHubService fragment = new SensorHubService();
        mCurrentservice = service;
        mExtraservice = gattExtraServiceData;
        return fragment;
    }

    /**
     * Display the atmospheric pressure threshold data
     *
     * @param string
     */
    protected void displaySPressureThresholdData(String string) {
        LogUtil.e("SensorHubService", "displaySPressureThresholdData()");
        if (mSpressureThresholdValue != null) {
            mSpressureThresholdValue.setText(string);
        }

    }

    /**
     * Display atmospheric pressure data
     *
     * @param pressure
     */
    void displaySPressureData(final String pressure) {
        LogUtil.e("SensorHubService", "displaySPressureData()");
        mSensorPressure.setText(pressure);
        final Handler lHandler = new Handler();
        Runnable lRunnable = new Runnable() {

            @Override
            public void run() {
                if (mHandlerFlag) {
                    mSPressureGraphLastXValue++;
                    double value = Integer.valueOf(pressure);
                    mPressureDataSeries.add(mSPressureGraphLastXValue, value);
                    mPressureChart.repaint();
                }

            }
        };
        lHandler.postDelayed(lRunnable, HANDLER_DELAY);
    }

    /**
     * Display temperature data
     *
     * @param received_stemp
     */
    void displaySTEMPData(final String received_stemp) {
        LogUtil.e("SensorHubService", "displaySTEMPData()");
        mSensorTemp.setText(received_stemp);
        final Handler lHandler = new Handler();
        Runnable lRunnable = new Runnable() {

            @Override
            public void run() {
                if (mHandlerFlag) {
                    mSTempGraphLastXValue++;
                    double value = Float.valueOf(received_stemp);
                    mTemperatureDataSeries.add(mSTempGraphLastXValue, value);
                    mTemperaturerChart.repaint();
                }

            }
        };
        lHandler.postDelayed(lRunnable, HANDLER_DELAY);

    }

    /**
     * Display battery information
     *
     * @param val
     */
    void displayBATData(String val) {
        LogUtil.e("SensorHubService", "displayBATData()");
        mBattery.setText(val);
    }

    /**
     * Display accelerometer X Value
     *
     * @param val
     */
    void displayXData(final String val) {
        LogUtil.e("SensorHubService", "displayXData()");
        mAccX.setText(val);
        final Handler lHandler = new Handler();
        Runnable lRunnable = new Runnable() {
            @Override
            public void run() {
                if (mHandlerFlag) {
                    mACCXGraphLastXValue++;
                    double value = Integer.valueOf(val);
                    mAccXDataSeries.add(mACCXGraphLastXValue, value);
                    mAccelerometerChart.repaint();

                }

            }
        };
        lHandler.postDelayed(lRunnable, HANDLER_DELAY);
    }

    /**
     * Display accelerometer Y Value
     *
     * @param val
     */
    void displayYData(final String val) {
        LogUtil.e("SensorHubService", "displayYData()");
        mAccY.setText(val);
        final Handler lHandler = new Handler();
        Runnable lRunnable = new Runnable() {

            @Override
            public void run() {
                if (mHandlerFlag) {
                    mACCYGraphLastXValue++;
                    double value = Integer.valueOf(val);
                    mAccYDataSeries.add(mACCYGraphLastXValue, value);
                    mAccelerometerChart.repaint();
                }

            }
        };
        lHandler.postDelayed(lRunnable, HANDLER_DELAY);
    }

    /**
     * Display accelerometer Z Value
     *
     * @param val
     */
    void displayZData(final String val) {
        LogUtil.e("SensorHubService", "displayZData()");
        mAccZ.setText(val);
        final Handler lHandler = new Handler();
        Runnable lRunnable = new Runnable() {

            @Override
            public void run() {
                if (mHandlerFlag) {
                    mACCZGraphLastXValue++;
                    double value = Integer.valueOf(val);
                    mAccZDataSeries.add(mACCZGraphLastXValue, value);
                    mAccelerometerChart.repaint();

                }

            }
        };
        lHandler.postDelayed(lRunnable, HANDLER_DELAY);
    }

    /**
     * Display accelerometer scan interval data
     *
     * @param val
     */
    protected void displayAccSensorScanData(String val) {
        LogUtil.e("SensorHubService", "displayAccSensorScanData()");
        if (mAccScanInterval != null) {
            mAccScanInterval.setText(val);
        }

    }

    /**
     * Display accelerometer sensor type data
     *
     * @param val
     */

    protected void displayAccSensorTypeData(String val) {
        LogUtil.e("SensorHubService", "displayAccSensorTypeData()");
        if (mAccSensortype != null) {
            mAccSensortype.setText(val);

        }

    }

    /**
     * Display temperature sensor scan interval
     *
     * @param val
     */
    protected void displayStempSensorScanData(String val) {
        LogUtil.e("SensorHubService", "displayStempSensorScanData()");
        if (mStempScanInterval != null) {
            mStempScanInterval.setText(val);

        }

    }

    /**
     * Display temperature sensor type
     *
     * @param val
     */

    protected void displayStempSensorTypeData(String val) {
        LogUtil.e("SensorHubService", "displayStempSensorTypeData()");
        if (mStempSensortype != null) {
            mStempSensortype.setText(val);

        }

    }

    /**
     * Display pressure sensor scan interval
     *
     * @param val
     */
    protected void displaySpressureSensorScanData(String val) {
        LogUtil.e("SensorHubService", "displaySpressureSensorScanData()");
        if (mSpressureScanInterval != null) {
            mSpressureScanInterval.setText(val);
        }
    }

    /**
     * Display pressure sensor type
     *
     * @param val
     */

    protected void displaySPressureSensorTypeData(String val) {
        LogUtil.e("SensorHubService", "displaySPressureSensorTypeData()");
        if (mSpressureSensortype != null) {
            mSpressureSensortype.setText(val);

        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        LogUtil.e("SensorHubService", "onCreateView()");
        final View rootView = inflater.inflate(R.layout.sensor_hub, container,
                false);
        mAccX = (TextView) rootView.findViewById(R.id.acc_x_value);
        mAccY = (TextView) rootView.findViewById(R.id.acc_y_value);
        mAccZ = (TextView) rootView.findViewById(R.id.acc_z_value);
        mBattery = (TextView) rootView.findViewById(R.id.bat_value);
        mSensorTemp = (TextView) rootView.findViewById(R.id.temp_value);
        mProgressDialog = new ProgressDialog(getActivity());
        mSensorPressure = (TextView) rootView.findViewById(R.id.pressure_value);

        // Locate device button listener
        Button locateDevice = (Button) rootView
                .findViewById(R.id.locate_device);
        locateDevice.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                Button btn = (Button) v;
                String buttonText = btn.getText().toString();
                String startText = getResources().getString(
                        R.string.sen_hub_locate);
                String stopText = getResources().getString(
                        R.string.sen_hub_locate_stop);
                if (buttonText.equalsIgnoreCase(startText)) {
                    btn.setText(stopText);
                    if (mWriteAlertCharacteristic != null) {
                        byte[] convertedBytes = convertingTobyteArray(
                                IMM_HIGH_ALERT);
                        BluetoothLeService.writeCharacteristicNoresponse(
                                mWriteAlertCharacteristic, convertedBytes);
                    }

                } else {
                    btn.setText(startText);
                    if (mWriteAlertCharacteristic != null) {
                        byte[] convertedBytes = convertingTobyteArray(
                                IMM_NO_ALERT);
                        BluetoothLeService.writeCharacteristicNoresponse(
                                mWriteAlertCharacteristic, convertedBytes);
                    }
                }

            }
        });
        final ImageButton acc_more = (ImageButton) rootView
                .findViewById(R.id.acc_more);
        final ImageButton stemp_more = (ImageButton) rootView
                .findViewById(R.id.stemp_more);
        final ImageButton spressure_more = (ImageButton) rootView
                .findViewById(R.id.spressure_more);

        final LinearLayout acc_layLayout = (LinearLayout) rootView
                .findViewById(R.id.acc_context_menu);
        final LinearLayout stemp_layLayout = (LinearLayout) rootView
                .findViewById(R.id.stemp_context_menu);
        final LinearLayout spressure_layLayout = (LinearLayout) rootView
                .findViewById(R.id.spressure_context_menu);

        // expand listener
        acc_more.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                if (acc_layLayout.getVisibility() != View.VISIBLE) {
                    acc_more.setRotation(ROTATION_90);
                    CustomSlideAnimation a = new CustomSlideAnimation(
                            acc_layLayout, CustomSlideAnimation.EXPAND);
                    a.setHeight(mHeight);
                    acc_layLayout.startAnimation(a);
                    mAccScanInterval = (EditText) rootView
                            .findViewById(R.id.acc_sensor_scan_interval);
                    if (ACCSensorScanCharacteristic != null) {
                        mAccScanInterval.setText(ACCSensorScanCharacteristic);
                    }
                    mAccSensortype = (TextView) rootView
                            .findViewById(R.id.acc_sensor_type);
                    if (ACCSensorTypeCharacteristic != null) {
                        mAccSensortype.setText(ACCSensorTypeCharacteristic);
                    }
                    mAccScanInterval
                            .setOnEditorActionListener(new OnEditorActionListener() {

                                @Override
                                public boolean onEditorAction(TextView v,
                                                              int actionId, KeyEvent event) {
                                    if (actionId == EditorInfo.IME_ACTION_DONE) {
                                        int myNum = 0;

                                        try {
                                            myNum = Integer
                                                    .parseInt(mAccScanInterval
                                                            .getText()
                                                            .toString());
                                        } catch (NumberFormatException nfe) {
                                            nfe.printStackTrace();
                                        }
                                        byte[] convertedBytes = convertingTobyteArray(
                                                Integer.toString(myNum));
                                        BluetoothLeService
                                                .writeCharacteristicNoresponse(
                                                        mReadACCSensorScanCharacteristic,
                                                        convertedBytes);
                                    }
                                    return false;
                                }
                            });
                    Spinner spinner_filterconfiguration = (Spinner) rootView
                            .findViewById(R.id.acc_filter_configuration);
                    // Create an ArrayAdapter using the string array and a
                    // default
                    // spinner layout
                    ArrayAdapter<CharSequence> adapter_filterconfiguration = ArrayAdapter
                            .createFromResource(getActivity(),
                                    R.array.filter_configuration_alert_array,
                                    android.R.layout.simple_spinner_item);
                    // Specify the layout to use when the list of choices
                    // appears
                    adapter_filterconfiguration
                            .setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                    // Apply the adapter to the spinner
                    spinner_filterconfiguration
                            .setAdapter(adapter_filterconfiguration);

                } else {
                    acc_more.setRotation(ROTATION_N90);

                    mAccScanInterval.setText("");
                    mAccSensortype.setText("");
                    CustomSlideAnimation a = new CustomSlideAnimation(
                            acc_layLayout, CustomSlideAnimation.COLLAPSE);
                    mHeight = a.getHeight();
                    acc_layLayout.startAnimation(a);
                }
            }
        });
        // expand listener
        stemp_more.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {

                if (stemp_layLayout.getVisibility() != View.VISIBLE) {
                    stemp_more.setRotation(ROTATION_90);
                    CustomSlideAnimation a = new CustomSlideAnimation(
                            stemp_layLayout, CustomSlideAnimation.EXPAND);
                    a.setHeight(mHeight);
                    stemp_layLayout.startAnimation(a);
                    mStempScanInterval = (EditText) rootView
                            .findViewById(R.id.stemp_sensor_scan_interval);
                    if (STEMPSensorScanCharacteristic != null) {
                        mStempScanInterval
                                .setText(STEMPSensorScanCharacteristic);
                    }
                    mStempSensortype = (TextView) rootView
                            .findViewById(R.id.stemp_sensor_type);
                    if (STEMPSensorTypeCharacteristic != null) {
                        mStempSensortype.setText(STEMPSensorTypeCharacteristic);
                    }
                    mStempScanInterval
                            .setOnEditorActionListener(new OnEditorActionListener() {

                                @Override
                                public boolean onEditorAction(TextView v,
                                                              int actionId, KeyEvent event) {
                                    if (actionId == EditorInfo.IME_ACTION_DONE) {
                                        int myNum = 0;

                                        try {
                                            myNum = Integer
                                                    .parseInt(mStempScanInterval
                                                            .getText()
                                                            .toString());
                                        } catch (NumberFormatException nfe) {
                                            nfe.printStackTrace();
                                        }
                                        byte[] convertedBytes = convertingTobyteArray(
                                                Integer.toString(myNum));
                                        BluetoothLeService
                                                .writeCharacteristicNoresponse(
                                                        mReadSTEMPSensorScanCharacteristic,
                                                        convertedBytes);
                                    }
                                    return false;
                                }
                            });

                } else {
                    stemp_more.setRotation(ROTATION_N90);
                    mStempScanInterval.setText("");
                    mStempSensortype.setText("");
                    CustomSlideAnimation a = new CustomSlideAnimation(
                            stemp_layLayout, CustomSlideAnimation.COLLAPSE);
                    mHeight = a.getHeight();
                    stemp_layLayout.startAnimation(a);
                }
            }
        });
        // expand listener
        spressure_more.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                if (spressure_layLayout.getVisibility() != View.VISIBLE) {
                    spressure_more.setRotation(ROTATION_90);
                    CustomSlideAnimation a = new CustomSlideAnimation(
                            spressure_layLayout,
                            CustomSlideAnimation.EXPAND);
                    a.setHeight(mHeight);
                    spressure_layLayout.startAnimation(a);
                    mSpressureScanInterval = (EditText) rootView
                            .findViewById(R.id.spressure_sensor_scan_interval);
                    if (SPRESSURESensorScanCharacteristic != null) {
                        mSpressureScanInterval
                                .setText(SPRESSURESensorScanCharacteristic);
                    }
                    mSpressureSensortype = (TextView) rootView
                            .findViewById(R.id.spressure_sensor_type);
                    if (SPRESSURESensorTypeCharacteristic != null) {
                        mSpressureSensortype
                                .setText(SPRESSURESensorTypeCharacteristic);
                    }
                    mSpressureScanInterval
                            .setOnEditorActionListener(new OnEditorActionListener() {

                                @Override
                                public boolean onEditorAction(TextView v,
                                                              int actionId, KeyEvent event) {
                                    if (actionId == EditorInfo.IME_ACTION_DONE) {
                                        int myNum = 0;

                                        try {
                                            myNum = Integer
                                                    .parseInt(mStempScanInterval
                                                            .getText()
                                                            .toString());
                                        } catch (NumberFormatException nfe) {
                                            nfe.printStackTrace();
                                        }
                                        byte[] convertedBytes = convertingTobyteArray(
                                                Integer.toString(myNum));
                                        BluetoothLeService
                                                .writeCharacteristicNoresponse(
                                                        mReadSPRESSURESensorScanCharacteristic,
                                                        convertedBytes);
                                    }
                                    return false;
                                }
                            });
                    Spinner spinner_filterconfiguration = (Spinner) rootView
                            .findViewById(R.id.spressure_filter_configuration);
                    // Create an ArrayAdapter using the string array and a
                    // default
                    // spinner layout
                    ArrayAdapter<CharSequence> adapter_filterconfiguration = ArrayAdapter
                            .createFromResource(getActivity(),
                                    R.array.filter_configuration_alert_array,
                                    android.R.layout.simple_spinner_item);
                    // Specify the layout to use when the list of choices
                    // appears
                    adapter_filterconfiguration
                            .setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                    // Apply the adapter to the spinner
                    spinner_filterconfiguration
                            .setAdapter(adapter_filterconfiguration);
                    mSpressureThresholdValue = (EditText) rootView
                            .findViewById(R.id.spressure_threshold);
                    mSpressureThresholdValue
                            .setOnEditorActionListener(new OnEditorActionListener() {

                                @Override
                                public boolean onEditorAction(TextView v,
                                                              int actionId, KeyEvent event) {
                                    if (actionId == EditorInfo.IME_ACTION_DONE) {
                                        int myNum = 0;

                                        try {
                                            myNum = Integer
                                                    .parseInt(mSpressureThresholdValue
                                                            .getText()
                                                            .toString());
                                        } catch (NumberFormatException nfe) {
                                            nfe.printStackTrace();
                                        }
                                        byte[] convertedBytes = convertingTobyteArray(
                                                Integer.toString(myNum));
                                        BluetoothLeService
                                                .writeCharacteristicNoresponse(
                                                        mReadSPRESSUREThresholdCharacteristic,
                                                        convertedBytes);
                                    }
                                    return false;
                                }
                            });

                } else {
                    spressure_more.setRotation(ROTATION_N90);
                    mSpressureScanInterval.setText("");
                    mSpressureSensortype.setText("");
                    mSpressureThresholdValue.setText("");
                    CustomSlideAnimation a = new CustomSlideAnimation(
                            spressure_layLayout,
                            CustomSlideAnimation.COLLAPSE);
                    mHeight = a.getHeight();
                    spressure_layLayout.startAnimation(a);
                }

            }
        });
        ImageButton acc_graph = (ImageButton) rootView
                .findViewById(R.id.acc_graph);
        setupAccChart(rootView);

        acc_graph.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                if (mACCGraphLayoutParent.getVisibility() != View.VISIBLE) {
                    mACCGraphLayoutParent.setVisibility(View.VISIBLE);

                } else {
                    mACCGraphLayoutParent.setVisibility(View.GONE);
                }

            }
        });
        ImageButton stemp_graph = (ImageButton) rootView
                .findViewById(R.id.temp_graph);
        setupTempGraph(rootView);
        stemp_graph.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                if (mTemperatureGraphLayoutParent.getVisibility() != View.VISIBLE) {
                    mTemperatureGraphLayoutParent.setVisibility(View.VISIBLE);
                } else {
                    mTemperatureGraphLayoutParent.setVisibility(View.GONE);
                }

            }
        });
        ImageButton spressure_graph = (ImageButton) rootView
                .findViewById(R.id.pressure_graph);
        setupPressureGraph(rootView);

        spressure_graph.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                if (mPressureGraphLayoutParent.getVisibility() != View.VISIBLE) {
                    mPressureGraphLayoutParent.setVisibility(View.VISIBLE);

                } else {

                    mPressureGraphLayoutParent.setVisibility(View.GONE);
                }

            }
        });
        setHasOptionsMenu(true);
        return rootView;
    }

    private void setupPressureGraph(View parent) {
        {
            LogUtil.e("SensorHubService", " setupPressureGraph()");
            /**
             * Setting graph titles
             */
            String graphTitle = getResources().getString(R.string.sen_hub_pressure);
            String graphXAxis = getResources().getString(R.string.health_temperature_time);
            String graphYAxis = getResources().getString(R.string.sen_hub_pressure);


            // Creating an  XYSeries for temperature
            mPressureDataSeries = new XYSeries(graphTitle);


            // Creating a dataset to hold each series
            XYMultipleSeriesDataset mDataset = new XYMultipleSeriesDataset();

            // Adding temperature Series to the dataset
            mDataset.addSeries(mPressureDataSeries);


            // Creating XYSeriesRenderer to customize
            XYSeriesRenderer mRenderer = new XYSeriesRenderer();
            mRenderer.setColor(getResources().getColor(R.color.main_bg_color));
            mRenderer.setPointStyle(PointStyle.CIRCLE);
            mRenderer.setFillPoints(true);
            mRenderer.setLineWidth(5);

            // Creating a XYMultipleSeriesRenderer to customize the whole chart
            XYMultipleSeriesRenderer mMultiRenderer = new XYMultipleSeriesRenderer();
            int deviceDPi = getResources().getDisplayMetrics().densityDpi;
            switch (deviceDPi) {
                case DisplayMetrics.DENSITY_XHIGH:
                    mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_40, Constants.GRAPH_MARGIN_90,
                            Constants.GRAPH_MARGIN_25, Constants.GRAPH_MARGIN_10});
                    mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_XHDPI);
                    mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_XHDPI);
                    mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_XHDPI);
                    mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_XHDPI);
                    break;
                case DisplayMetrics.DENSITY_HIGH:
                    mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_30, Constants.GRAPH_MARGIN_50,
                            Constants.GRAPH_MARGIN_25, Constants.GRAPH_MARGIN_10});
                    mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_HDPI);
                    mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_HDPI);
                    mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_HDPI);
                    mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_HDPI);
                    break;
                case DisplayMetrics.DENSITY_XXHIGH:
                    mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_50, Constants.GRAPH_MARGIN_100,
                            Constants.GRAPH_MARGIN_35, Constants.GRAPH_MARGIN_20});
                    mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_XXXHDPI);
                    mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_XXXHDPI);
                    mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_XXXHDPI);
                    mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_XXXHDPI);
                    break;

                default:
                    if (deviceDPi > DisplayMetrics.DENSITY_XXHIGH && deviceDPi <=
                            DisplayMetrics.DENSITY_XXXHIGH) {
                        mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_50, Constants.GRAPH_MARGIN_100,
                                Constants.GRAPH_MARGIN_35, Constants.GRAPH_MARGIN_20});
                        mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_XXXHDPI);
                        mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_XXXHDPI);
                        mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_XXXHDPI);
                        mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_XXXHDPI);
                    } else {
                        mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_30, Constants.GRAPH_MARGIN_50,
                                Constants.GRAPH_MARGIN_25, Constants.GRAPH_MARGIN_10});
                        mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_LDPI);
                        mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_LDPI);
                        mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_LDPI);
                        mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_LDPI);
                    }
                    break;
            }
            mMultiRenderer.setXTitle(graphXAxis);
            mMultiRenderer.setLabelsColor(Color.BLACK);
            mMultiRenderer.setYTitle(graphYAxis);
            mMultiRenderer.setMarginsColor(Color.argb(0x00, 0xff, 0x00, 0x00));
            mMultiRenderer.setPanEnabled(true, true);
            mMultiRenderer.setZoomEnabled(false,false);
            mMultiRenderer.setGridColor(Color.LTGRAY);
            mMultiRenderer.setLabelsColor(Color.BLACK);
            mMultiRenderer.setYLabelsColor(0, Color.DKGRAY);
            mMultiRenderer.setYLabelsAlign(Paint.Align.RIGHT);
            mMultiRenderer.setXLabelsColor(Color.DKGRAY);
            mMultiRenderer.setYLabelsColor(0, Color.BLACK);
            mMultiRenderer.setXLabelsColor(Color.BLACK);
            mMultiRenderer.setApplyBackgroundColor(true);
            mMultiRenderer.setBackgroundColor(Color.WHITE);
            mMultiRenderer.setGridColor(Color.BLACK);
            mMultiRenderer.setShowGrid(true);
            mMultiRenderer.setShowLegend(false);


            // Adding mRenderer to multipleRenderer
            mMultiRenderer.addSeriesRenderer(mRenderer);

            // Getting a reference to LinearLayout of the MainActivity Layout
            mPressureGraphLayoutParent = (LinearLayout) parent.findViewById(R.id.
                    pressure_chart_container);


            mPressureChart = ChartFactory.getLineChartView(getActivity(),
                    mDataset, mMultiRenderer);


            // Adding the Line Chart to the LinearLayout
            mPressureGraphLayoutParent.addView(mPressureChart);

        }
    }

    private void setupTempGraph(View parent) {
        {
            LogUtil.e("SensorHubService", "setupTempGraph()");
            /**
             * Setting graph titles
             */
            String graphTitle = getResources().getString(R.string.sen_hub_temperature);
            String graphXAxis = getResources().getString(R.string.health_temperature_time);
            String graphYAxis = getResources().getString(R.string.sen_hub_temperature);


            // Creating an  XYSeries for temperature
            mTemperatureDataSeries = new XYSeries(graphTitle);


            // Creating a dataset to hold each series
            XYMultipleSeriesDataset mDataset = new XYMultipleSeriesDataset();

            // Adding temperature Series to the dataset
            mDataset.addSeries(mTemperatureDataSeries);


            // Creating XYSeriesRenderer to customize
            XYSeriesRenderer mRenderer = new XYSeriesRenderer();
            mRenderer.setColor(getResources().getColor(R.color.main_bg_color));
            mRenderer.setPointStyle(PointStyle.CIRCLE);
            mRenderer.setFillPoints(true);
            mRenderer.setLineWidth(5);

            // Creating a XYMultipleSeriesRenderer to customize the whole chart
            XYMultipleSeriesRenderer mMultiRenderer = new XYMultipleSeriesRenderer();
            int deviceDPi = getResources().getDisplayMetrics().densityDpi;
            switch (deviceDPi) {
                case DisplayMetrics.DENSITY_XHIGH:
                    mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_40, Constants.GRAPH_MARGIN_90,
                            Constants.GRAPH_MARGIN_25, Constants.GRAPH_MARGIN_10});
                    mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_XHDPI);
                    mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_XHDPI);
                    mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_XHDPI);
                    mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_XHDPI);
                    break;
                case DisplayMetrics.DENSITY_HIGH:
                    mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_30, Constants.GRAPH_MARGIN_50,
                            Constants.GRAPH_MARGIN_25, Constants.GRAPH_MARGIN_10});
                    mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_HDPI);
                    mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_HDPI);
                    mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_HDPI);
                    mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_HDPI);
                    break;
                case DisplayMetrics.DENSITY_XXHIGH:
                    mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_50, Constants.GRAPH_MARGIN_100,
                            Constants.GRAPH_MARGIN_35, Constants.GRAPH_MARGIN_20});
                    mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_XXHDPI);
                    mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_XXHDPI);
                    mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_XXHDPI);
                    mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_XXHDPI);
                    break;

                default:
                    if (deviceDPi > DisplayMetrics.DENSITY_XXHIGH && deviceDPi <=
                            DisplayMetrics.DENSITY_XXXHIGH) {
                        mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_50, Constants.GRAPH_MARGIN_100,
                                Constants.GRAPH_MARGIN_35, Constants.GRAPH_MARGIN_20});
                        mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_XXXHDPI);
                        mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_XXXHDPI);
                        mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_XXXHDPI);
                        mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_XXXHDPI);
                    } else {
                        mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_30, Constants.GRAPH_MARGIN_50,
                                Constants.GRAPH_MARGIN_25, Constants.GRAPH_MARGIN_10});
                        mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_LDPI);
                        mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_LDPI);
                        mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_LDPI);
                        mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_LDPI);
                    }
                    break;
            }
            mMultiRenderer.setXTitle(graphXAxis);
            mMultiRenderer.setLabelsColor(Color.BLACK);
            mMultiRenderer.setYTitle(graphYAxis);
            mMultiRenderer.setMarginsColor(Color.argb(0x00, 0xff, 0x00, 0x00));
            mMultiRenderer.setPanEnabled(true, true);
            mMultiRenderer.setZoomEnabled(false,false);
            mMultiRenderer.setGridColor(Color.LTGRAY);
            mMultiRenderer.setLabelsColor(Color.BLACK);
            mMultiRenderer.setYLabelsColor(0, Color.DKGRAY);
            mMultiRenderer.setYLabelsAlign(Paint.Align.RIGHT);
            mMultiRenderer.setXLabelsColor(Color.DKGRAY);
            mMultiRenderer.setYLabelsColor(0, Color.BLACK);
            mMultiRenderer.setXLabelsColor(Color.BLACK);
            mMultiRenderer.setApplyBackgroundColor(true);
            mMultiRenderer.setBackgroundColor(Color.WHITE);
            mMultiRenderer.setGridColor(Color.BLACK);
            mMultiRenderer.setShowGrid(true);
            mMultiRenderer.setShowLegend(false);


            // Adding mRenderer to multipleRenderer
            mMultiRenderer.addSeriesRenderer(mRenderer);

            // Getting a reference to LinearLayout of the MainActivity Layout
            mTemperatureGraphLayoutParent = (LinearLayout) parent.findViewById(R.id.
                    temp_chart_container);


            mTemperaturerChart = ChartFactory.getLineChartView(getActivity(),
                    mDataset, mMultiRenderer);


            // Adding the Line Chart to the LinearLayout
            mTemperatureGraphLayoutParent.addView(mTemperaturerChart);

        }
    }

    /**
     * Setting accelerometer graph
     *
     * @param parent
     */
    private void setupAccChart(View parent) {
        LogUtil.e("SensorHubService", "setupAccChart()");
        /**
         * Setting graph titles
         */
        String graphXTitle = getResources().getString(R.string.sen_hub_accelerometer_x);
        String graphYTitle = getResources().getString(R.string.sen_hub_accelerometer_Y);
        String graphZTitle = getResources().getString(R.string.sen_hub_accelerometer_Z);
        String graphXAxis = getResources().getString(R.string.health_temperature_time);
        String graphYAxis = getResources().getString(R.string.sen_hub_accelerometer);


        // Creating an  XYSeries for Accelerometer
        mAccXDataSeries = new XYSeries(graphXTitle);
        mAccYDataSeries = new XYSeries(graphYTitle);
        mAccZDataSeries = new XYSeries(graphZTitle);


        // Creating a dataset to hold each series
        XYMultipleSeriesDataset mDataset = new XYMultipleSeriesDataset();

        // Adding temperature Series to the dataset
        mDataset.addSeries(mAccXDataSeries);
        mDataset.addSeries(mAccYDataSeries);
        mDataset.addSeries(mAccZDataSeries);


        // Creating XYSeriesRenderer to customize
        XYSeriesRenderer mXRenderer = new XYSeriesRenderer();
        mXRenderer.setColor(Color.RED);
        mXRenderer.setPointStyle(PointStyle.CIRCLE);
        mXRenderer.setFillPoints(true);
        mXRenderer.setLineWidth(5);

        XYSeriesRenderer mYRenderer = new XYSeriesRenderer();
        mYRenderer.setColor(Color.BLUE);
        mYRenderer.setPointStyle(PointStyle.CIRCLE);
        mYRenderer.setFillPoints(true);
        mYRenderer.setLineWidth(5);

        XYSeriesRenderer mZRenderer = new XYSeriesRenderer();
        mZRenderer.setColor(Color.GREEN);
        mZRenderer.setPointStyle(PointStyle.CIRCLE);
        mZRenderer.setFillPoints(true);
        mZRenderer.setLineWidth(5);

        // Creating a XYMultipleSeriesRenderer to customize the whole chart
        XYMultipleSeriesRenderer mMultiRenderer = new XYMultipleSeriesRenderer();
        int deviceDPi = getResources().getDisplayMetrics().densityDpi;
        switch (deviceDPi) {
            case DisplayMetrics.DENSITY_XHIGH:
                mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_40, Constants.GRAPH_MARGIN_90,
                        Constants.GRAPH_MARGIN_25, Constants.GRAPH_MARGIN_10});
                mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_XHDPI);
                mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_XHDPI);
                mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_XHDPI);
                mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_XHDPI);
                break;
            case DisplayMetrics.DENSITY_HIGH:
                mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_30, Constants.GRAPH_MARGIN_50,
                        Constants.GRAPH_MARGIN_25, Constants.GRAPH_MARGIN_10});
                mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_HDPI);
                mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_HDPI);
                mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_HDPI);
                mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_HDPI);
                break;
            case DisplayMetrics.DENSITY_XXHIGH:
                mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_50, Constants.GRAPH_MARGIN_100,
                        Constants.GRAPH_MARGIN_35, Constants.GRAPH_MARGIN_20});
                mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_XXHDPI);
                mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_XXHDPI);
                mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_XXHDPI);
                mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_XXHDPI);
                break;

            default:
                if (deviceDPi > DisplayMetrics.DENSITY_XXHIGH && deviceDPi <=
                        DisplayMetrics.DENSITY_XXXHIGH) {
                    mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_50, Constants.GRAPH_MARGIN_100,
                            Constants.GRAPH_MARGIN_35, Constants.GRAPH_MARGIN_20});
                    mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_XXXHDPI);
                    mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_XXXHDPI);
                    mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_XXXHDPI);
                    mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_XXXHDPI);
                } else {
                    mMultiRenderer.setMargins(new int[]{Constants.GRAPH_MARGIN_30, Constants.GRAPH_MARGIN_50,
                            Constants.GRAPH_MARGIN_25, Constants.GRAPH_MARGIN_10});
                    mMultiRenderer.setAxisTitleTextSize(Constants.TEXT_SIZE_LDPI);
                    mMultiRenderer.setChartTitleTextSize(Constants.TEXT_SIZE_LDPI);
                    mMultiRenderer.setLabelsTextSize(Constants.TEXT_SIZE_LDPI);
                    mMultiRenderer.setLegendTextSize(Constants.TEXT_SIZE_LDPI);
                }
                break;
        }
        mMultiRenderer.setXTitle(graphXAxis);
        mMultiRenderer.setLabelsColor(Color.BLACK);
        mMultiRenderer.setYTitle(graphYAxis);
        mMultiRenderer.setMarginsColor(Color.argb(0x00, 0xff, 0x00, 0x00));
        mMultiRenderer.setPanEnabled(true, true);
        mMultiRenderer.setZoomEnabled(false,false);
        mMultiRenderer.setGridColor(Color.LTGRAY);
        mMultiRenderer.setLabelsColor(Color.BLACK);
        mMultiRenderer.setYLabelsColor(0, Color.DKGRAY);
        mMultiRenderer.setYLabelsAlign(Paint.Align.RIGHT);
        mMultiRenderer.setXLabelsColor(Color.DKGRAY);
        mMultiRenderer.setYLabelsColor(0, Color.BLACK);
        mMultiRenderer.setXLabelsColor(Color.BLACK);
        mMultiRenderer.setApplyBackgroundColor(true);
        mMultiRenderer.setBackgroundColor(Color.WHITE);
        mMultiRenderer.setGridColor(Color.BLACK);
        mMultiRenderer.setShowGrid(true);
        mMultiRenderer.setShowLegend(false);


        // Adding mRenderer to multipleRenderer
        mMultiRenderer.addSeriesRenderer(mXRenderer);
        mMultiRenderer.addSeriesRenderer(mYRenderer);
        mMultiRenderer.addSeriesRenderer(mZRenderer);

        // Getting a reference to LinearLayout of the MainActivity Layout
        mACCGraphLayoutParent = (LinearLayout) parent.findViewById(R.id.accelerometer_chart_container);


        mAccelerometerChart = ChartFactory.getLineChartView(getActivity(),
                mDataset, mMultiRenderer);


        // Adding the Line Chart to the LinearLayout
        mACCGraphLayoutParent.addView(mAccelerometerChart);


    }

    @Override
    public void onResume() {
        super.onResume();
        LogUtil.e("SensorHubService", "onResume()");
        mHandlerFlag = true;
        getGattData();
        getActivity().registerReceiver(mGattUpdateReceiver,
                Utils.makeGattUpdateIntentFilter());
        Utils.setUpActionBar(getActivity(),
                getResources().getString(R.string.sen_hub));
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        LogUtil.e("SensorHubService", "onDestroy()");
        mHandlerFlag = false;
        getActivity().unregisterReceiver(mGattUpdateReceiver);
        stopBroadcastDataNotify(mNotifyACCXCharacteristic);
        stopBroadcastDataNotify(mNotifyACCYCharacteristic);
        stopBroadcastDataNotify(mNotifyACCZCharacteristic);
        stopBroadcastDataNotify(mNotifyBATCharacteristic);
        stopBroadcastDataNotify(mNotifySTEMPCharacteristic);
        stopBroadcastDataIndicate(mIndicateSPRESSURECharacteristic);
    }

    /**
     * Stopping Broadcast receiver to broadcast notify characteristics
     *
     * @param gattCharacteristic
     */
    private static void stopBroadcastDataNotify(
            BluetoothGattCharacteristic gattCharacteristic) {
        LogUtil.e("SensorHubService", "stopBroadcastDataNotify()");
        final int charaProp = gattCharacteristic.getProperties();

        if ((charaProp | BluetoothGattCharacteristic.PROPERTY_NOTIFY) > 0) {
            if (gattCharacteristic != null) {
                BluetoothLeService.setCharacteristicNotification(
                        gattCharacteristic, false);

            }

        }

    }

    /**
     * Stopping Broadcast receiver to broadcast indicate characteristics
     *
     * @param gattCharacteristic
     */
    private static void stopBroadcastDataIndicate(
            BluetoothGattCharacteristic gattCharacteristic) {
        LogUtil.e("SensorHubService", "stopBroadcastDataIndicate()");
        final int charaProp = gattCharacteristic.getProperties();

        if ((charaProp | BluetoothGattCharacteristic.PROPERTY_INDICATE) > 0) {
            if (gattCharacteristic != null) {
                BluetoothLeService.setCharacteristicNotification(
                        gattCharacteristic, false);

            }

        }

    }

    /**
     * Preparing Broadcast receiver to broadcast read characteristics
     *
     * @param gattCharacteristic
     */
    void prepareBroadcastDataRead(
            BluetoothGattCharacteristic gattCharacteristic) {
        LogUtil.e("SensorHubService", "prepareBroadcastDataRead()");
        final int charaProp = gattCharacteristic.getProperties();
        if ((charaProp | BluetoothGattCharacteristic.PROPERTY_READ) > 0) {
            BluetoothLeService.readCharacteristic(gattCharacteristic);
        }
    }

    /**
     * Preparing Broadcast receiver to broadcast notify characteristics
     *
     * @param gattCharacteristic
     */
    void prepareBroadcastDataNotify(
            BluetoothGattCharacteristic gattCharacteristic) {
        LogUtil.e("SensorHubService", "prepareBroadcastDataNotify()");
        final int charaProp = gattCharacteristic.getProperties();

        if ((charaProp | BluetoothGattCharacteristic.PROPERTY_NOTIFY) > 0) {
            BluetoothLeService.setCharacteristicNotification(gattCharacteristic,
                    true);

        }

    }

    /**
     * Preparing Broadcast receiver to broadcast indicate characteristics
     *
     * @param gattCharacteristic
     */
    void prepareBroadcastDataIndicate(
            BluetoothGattCharacteristic gattCharacteristic) {
        LogUtil.e("SensorHubService", "prepareBroadcastDataIndicate()");
        final int charaProp = gattCharacteristic.getProperties();

        if ((charaProp | BluetoothGattCharacteristic.PROPERTY_INDICATE) > 0) {
            BluetoothLeService.setCharacteristicNotification(gattCharacteristic,
                    true);

        }

    }

    /**
     * Method to get required characteristics from service
     */
    void getGattData() {
        LogUtil.e("SensorHubService", "getGattData()");
        for (int position = 0; position < mExtraservice.size(); position++) {
            HashMap<String, BluetoothGattService> item = mExtraservice
                    .get(position);
            BluetoothGattService bgs = item.get("UUID");
            if (bgs.getUuid().equals(UUIDDatabase.UUID_ACCELEROMETER_SERVICE)) {
                mAccservice = bgs;
            }
            List<BluetoothGattCharacteristic> gattCharacteristicsCurrent = bgs
                    .getCharacteristics();
            for (final BluetoothGattCharacteristic gattCharacteristic : gattCharacteristicsCurrent) {
                String uuidchara = gattCharacteristic.getUuid().toString();
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.ACCELEROMETER_READING_X)) {
                    mReadACCXCharacteristic = gattCharacteristic;
                    mNotifyACCXCharacteristic = gattCharacteristic;

                    prepareBroadcastDataRead(mReadACCXCharacteristic);
                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.ACCELEROMETER_READING_Y)) {
                    mReadACCYCharacteristic = gattCharacteristic;
                    mNotifyACCYCharacteristic = gattCharacteristic;

                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.ACCELEROMETER_READING_Z)) {
                    mReadACCZCharacteristic = gattCharacteristic;
                    mNotifyACCZCharacteristic = gattCharacteristic;
                }
                if (uuidchara.equalsIgnoreCase(GattAttributes.BATTERY_LEVEL)) {
                    mReadBATCharacteristic = gattCharacteristic;
                    mNotifyBATCharacteristic = gattCharacteristic;
                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.TEMPERATURE_READING)) {
                    mReadSTEMPCharacteristic = gattCharacteristic;
                    mNotifySTEMPCharacteristic = gattCharacteristic;
                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.BAROMETER_READING)) {
                    mReadSPRESSURECharacteristic = gattCharacteristic;
                    mIndicateSPRESSURECharacteristic = gattCharacteristic;
                }
                if (uuidchara.equalsIgnoreCase(GattAttributes.ALERT_LEVEL)) {
                    mWriteAlertCharacteristic = gattCharacteristic;

                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.ACCELEROMETER_SENSOR_SCAN_INTERVAL)) {
                    mReadACCSensorScanCharacteristic = gattCharacteristic;

                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.ACCELEROMETER_ANALOG_SENSOR)) {
                    mReadACCSensorTypeCharacteristic = gattCharacteristic;
                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.ACCELEROMETER_DATA_ACCUMULATION)) {
                    mReadACCFilterConfigurationCharacteristic = gattCharacteristic;
                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.TEMPERATURE_SENSOR_SCAN_INTERVAL)) {
                    mReadSTEMPSensorScanCharacteristic = gattCharacteristic;

                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.TEMPERATURE_ANALOG_SENSOR)) {
                    mReadSTEMPSensorTypeCharacteristic = gattCharacteristic;
                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.BAROMETER_SENSOR_SCAN_INTERVAL)) {
                    mReadSPRESSURESensorScanCharacteristic = gattCharacteristic;

                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.BAROMETER_DIGITAL_SENSOR)) {
                    mReadSPRESSURESensorTypeCharacteristic = gattCharacteristic;
                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.BAROMETER_DATA_ACCUMULATION)) {
                    mReadSPRESSUREFilterConfigurationCharacteristic = gattCharacteristic;
                }
                if (uuidchara
                        .equalsIgnoreCase(GattAttributes.BAROMETER_THRESHOLD_FOR_INDICATION)) {
                    mReadSPRESSUREThresholdCharacteristic = gattCharacteristic;
                }
            }
        }
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        LogUtil.e("SensorHubService", "onCreateOptionsMenu()");
        menu.clear();
        inflater.inflate(R.menu.global, menu);
        MenuItem graph = menu.findItem(R.id.graph);
        MenuItem log = menu.findItem(R.id.log);
        MenuItem search = menu.findItem(R.id.search);
        search.setVisible(false);
        graph.setVisible(false);
        log.setVisible(true);
        final MenuItem pairCache = menu.findItem(R.id.pairing);
        pairCache.setVisible(true);
        if (Utils.getBooleanSharedPreference(getActivity(), Constants.PREF_PAIR_CACHE_STATUS)) {
            pairCache.setChecked(true);
        } else {
            pairCache.setChecked(false);
        }

        super.onCreateOptionsMenu(menu, inflater);
    }

    /**
     * Method to convert hex to byteArray
     */
    private byte[] convertingTobyteArray(String result) {
        LogUtil.e("SensorHubService", "convertingTobyteArray()");
        String[] splited = result.split("\\s+");
        byte[] valueByte = new byte[splited.length];
        for (int i = 0; i < splited.length; i++) {
            if (splited[i].length() > 2) {
                String trimmedByte = splited[i].split("x")[1];
                valueByte[i] = (byte) convertstringtobyte(trimmedByte);
            }

        }
        return valueByte;
    }

    /**
     * Convert the string to byte
     *
     * @param string
     * @return
     */
    private int convertstringtobyte(String string) {
        LogUtil.e("SensorHubService", "convertstringtobyte()");
        return Integer.parseInt(string, 16);
    }

}