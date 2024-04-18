#
# This file is part of Edgehog.
#
# Copyright 2023 SECO Mind Srl
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
# SPDX-License-Identifier: Apache-2.0
#

defmodule Edgehog.Astarte.RealmTest do
  use Edgehog.DataCase, async: true

  @moduletag :ported_to_ash

  alias Edgehog.Astarte
  alias Edgehog.Astarte.Realm

  import Edgehog.AstarteFixtures
  import Edgehog.TenantsFixtures

  describe "create/2" do
    @valid_private_key X509.PrivateKey.new_ec(:secp256r1) |> X509.PrivateKey.to_pem()

    test "with valid data creates a realm" do
      cluster = cluster_fixture()
      tenant = tenant_fixture()
      valid_attrs = %{cluster_id: cluster.id, name: "somename", private_key: @valid_private_key}

      assert {:ok, %Realm{} = realm} = Realm.create(valid_attrs, tenant: tenant)
      assert realm.name == "somename"
      assert realm.private_key == @valid_private_key
      assert realm.tenant_id == tenant.tenant_id
    end

    test "with invalid name returns error" do
      assert {:error, %Ash.Error.Invalid{errors: [error]}} = create_realm(name: "42INVALID")
      assert %{field: :name} = error
    end

    test "with invalid private key returns error" do
      assert {:error, %Ash.Error.Invalid{errors: [error]}} =
               create_realm(private_key: "not a private key")

      assert %{field: :private_key} = error
    end

    test "with a duplicate name in the same tenant returns error" do
      tenant = tenant_fixture()
      cluster = cluster_fixture()
      realm = realm_fixture(cluster_id: cluster.id, tenant: tenant)

      assert {:error, %Ash.Error.Invalid{errors: [error]}} =
               create_realm(name: realm.name, tenant: tenant)

      assert %{field: :name, message: "has already been taken"} = error
    end

    test "with a duplicate name in the same cluster returns error" do
      other_tenant = tenant_fixture()
      cluster = cluster_fixture()
      realm = realm_fixture(tenant: other_tenant, cluster_id: cluster.id)

      assert {:error, %Ash.Error.Invalid{errors: [error]}} =
               create_realm(cluster_id: cluster.id, name: realm.name)

      assert %{field: :name, message: "has already been taken"} = error
    end

    test "with a duplicate name in another tenant and cluster succeeds" do
      other_tenant = tenant_fixture()
      other_cluster = cluster_fixture()
      realm = realm_fixture(tenant: other_tenant, cluster_id: other_cluster.id)

      assert {:ok, %Realm{} = _realm} = create_realm(name: realm.name)
    end
  end

  describe "fetch_by_name/2" do
    test "returns the realm given its name" do
      tenant = tenant_fixture()
      realm = realm_fixture(tenant: tenant)

      assert {:ok, realm} = Realm.fetch_by_name(realm.name, tenant: tenant, load: [:cluster])
    end

    test "returns error for non-existing realm" do
      tenant = tenant_fixture()

      assert {:error, %Ash.Error.Query.NotFound{}} =
               Realm.fetch_by_name("nonexisting", tenant: tenant)
    end
  end

  test "destroy/1 deletes the realm" do
    tenant = tenant_fixture()
    realm = realm_fixture(tenant: tenant)
    assert :ok = Realm.destroy(realm)

    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
             Astarte.get(Realm, realm.id, tenant: tenant)
  end

  defp create_realm(opts \\ []) do
    {tenant, opts} = Keyword.pop_lazy(opts, :tenant, &Edgehog.TenantsFixtures.tenant_fixture/0)

    {cluster_id, opts} =
      Keyword.pop_lazy(opts, :cluster_id, fn -> cluster_fixture() |> Map.fetch!(:id) end)

    opts
    |> Enum.into(%{
      cluster_id: cluster_id,
      name: unique_realm_name(),
      private_key: @valid_private_key
    })
    |> Edgehog.Astarte.Realm.create(tenant: tenant)
  end
end