#
# This file is part of Edgehog.
#
# Copyright 2021 SECO Mind Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

defmodule EdgehogWeb.Resolvers.AstarteTest do
  use EdgehogWeb.ConnCase
  use Edgehog.AstarteMockCase
  use Edgehog.GeolocationMockCase

  alias Edgehog.Astarte.Device.BatteryStatus.BatterySlot
  alias Edgehog.Astarte.Device.StorageUsage.StorageUnit
  alias Edgehog.Astarte.Device.{SystemStatus, WiFiScanResult}
  alias Edgehog.Geolocation
  alias EdgehogWeb.Resolvers.Astarte

  import Edgehog.AstarteFixtures

  describe "devices" do
    setup do
      cluster = cluster_fixture()
      realm = realm_fixture(cluster)
      device = device_fixture(realm)

      {:ok, cluster: cluster, realm: realm, device: device}
    end

    test "fetch_device_location/3 returns the location for a device", %{
      device: device
    } do
      assert {:ok, location} = Astarte.fetch_device_location(device, %{}, %{})

      assert %Geolocation{
               accuracy: 12,
               address: "4 Privet Drive, Little Whinging, Surrey, UK",
               latitude: 45.4095285,
               longitude: 11.8788231,
               timestamp: ~U[2021-11-15 11:44:57.432516Z]
             } == location
    end

    test "fetch_storage_usage/3 returns the storage usage for a device", %{
      device: device
    } do
      assert {:ok, storage_units} = Astarte.fetch_storage_usage(device, %{}, %{})

      assert [
               %StorageUnit{
                 label: "Disk 0",
                 total_bytes: 348_360_704,
                 free_bytes: 281_360_704
               }
             ] == storage_units
    end

    test "fetch_system_status/3 returns the system status for a device", %{
      device: device
    } do
      assert {:ok, system_status} = Astarte.fetch_system_status(device, %{}, %{})

      assert %SystemStatus{
               boot_id: "1c0cf72f-8428-4838-8626-1a748df5b889",
               memory_free_bytes: 166_772,
               task_count: 12,
               uptime_milliseconds: 5785,
               timestamp: ~U[2021-11-15 11:44:57.432516Z]
             } == system_status
    end

    test "fetch_wifi_scan_results/3 returns the wifi scans for a device", %{
      device: device
    } do
      assert {:ok, wifi_scan_results} = Astarte.fetch_wifi_scan_results(device, %{}, %{})

      assert [%WiFiScanResult{} | _rest] = wifi_scan_results
    end

    test "fetch_battery_status/3 returns the battery status for a device", %{
      device: device
    } do
      assert {:ok, battery_status} = Astarte.fetch_battery_status(device, %{}, %{})

      assert [
               %BatterySlot{
                 slot: "Slot name",
                 level_percentage: 80.3,
                 level_absolute_error: 0.1,
                 status: "Charging"
               }
               | _rest
             ] = battery_status
    end
  end
end