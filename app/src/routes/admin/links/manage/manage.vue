<template>
  <admin-view>
    <h1>Manage Links</h1>
    <n-data-table
      ref="tableRef"
      class="centered-view"
      :row-key="rowKey"
      :loading="loadingRef"
      :columns="columns"
      :data="links"
      :pagination="pagination"
    />
    <n-modal
      v-model:show="showEditModal"
      preset="card"
      :style="{ width: '600px' }"
      title="Modal"
      :bordered="false"
      size="huge"
      :segmented="{
        content: 'soft',
        footer: 'soft',
      }"
      :closable="false"
      :mask-closable="false"
    >
      <template #header>
        <div>Edit Link</div>
      </template>
      <div>
        <n-spin :show="showLoadingSpinner">
          <n-form ref="formRef" class="centered-form" :model="model" :rules="rules">
            <n-form-item path="url" label="URL">
              <n-input
                v-model:value="model.url_raw"
                class="url-input"
                pair
                clearable
                separator="://"
                :placeholder="['Protocol', 'Web Address']"
                @change="handleUrlUpdate"
                @update:value="handleUrlUpdate"
              ></n-input>
            </n-form-item>
            <n-row>
              <n-form-item ref="slugRef" path="slug" label="Slug" style="flex-grow: 1">
                <n-input-group>
                  <n-input-group-label class="slug-input-inline">/</n-input-group-label>
                  <n-input v-model:value="model.slug" class="slug-input" placeholder="Enter Slug" />
                </n-input-group>
              </n-form-item>
              <n-form-item>
                <n-button type="warning" style="margin-left: 20px" @click="handleGenerateSlug">
                  <template #icon>
                    <n-icon>
                      <sync />
                    </n-icon>
                  </template>
                  Generate Slug
                </n-button>
              </n-form-item>
            </n-row>
            <n-form-item path="android_url" label="Android URL" style="flex-grow: 1">
              <n-input
                v-model:value="model.android_url_raw"
                class="url-input"
                pair
                clearable
                separator="://"
                :placeholder="['Protocol', 'Web Address']"
                @change="handleAndroidUrlUpdate"
                @update:value="handleAndroidUrlUpdate"
              ></n-input>
            </n-form-item>
            <n-form-item path="ios_url" label="iOS URL" style="flex-grow: 1">
              <n-input
                v-model:value="model.ios_url_raw"
                class="url-input"
                pair
                clearable
                separator="://"
                :placeholder="['Protocol', 'Web Address']"
                @change="handleIosUrlUpdate"
                @update:value="handleIosUrlUpdate"
              ></n-input>
            </n-form-item>
          </n-form>
        </n-spin>
      </div>
      <template #footer>
        <div>
          <n-button type="primary" :disabled="showLoadingSpinner" @click="handleSaveEdits">Update</n-button
          ><n-button style="margin-left: 20px" :disabled="showLoadingSpinner" @click="showEditModal = false"
            >Cancel</n-button
          >
        </div>
      </template>
    </n-modal>
  </admin-view>
</template>

<script lang="ts">
import { defineComponent, ref, reactive, onMounted, h, computed } from 'vue';
import { fetchLinks, editLink, deleteLink } from '@/services/links';
import {
  useMessage,
  useDialog,
  NDataTable,
  NButton,
  NModal,
  NSpin,
  NForm,
  NFormItem,
  NInput,
  NInputGroup,
  NInputGroupLabel,
  NIcon,
  NRow,
} from 'naive-ui';
import { Sync } from '@vicons/fa';
import { useLinksStore } from '@/stores/linksStore';
import { Link } from '@/types/global';
import { customAlphabet } from 'nanoid';

export default defineComponent({
  components: {
    NDataTable,
    NModal,
    NSpin,
    NButton,
    NForm,
    NFormItem,
    NInput,
    NInputGroup,
    NInputGroupLabel,
    NIcon,
    NRow,
    Sync,
  },
  setup() {
    const slugRef = ref();
    const messageDuration = 5000;
    const linksStore = useLinksStore();
    const message = useMessage();
    const dialog = useDialog();
    const formRef = ref();
    const tableRef = ref();
    const loadingRef = ref(true);
    const links = ref<Link[] | []>([]);
    const showEditModal = ref(false);
    const showLoadingSpinner = ref(false);

    const modelRef: any = ref({
      url: computed(() => {
        if (!modelRef.value.url_raw[0] && !modelRef.value.url_raw[1]) return '';
        return modelRef.value.url_raw[0] + '://' + modelRef.value.url_raw[1];
      }),
      url_raw: ['', ''],
      slug: '',
      android_url: computed(() => {
        if (!modelRef.value.android_url_raw[0] && !modelRef.value.android_url_raw[1]) return '';
        return modelRef.value.android_url_raw[0] + '://' + modelRef.value.android_url_raw[1];
      }),
      android_url_raw: ['', ''],
      ios_url: computed(() => {
        if (!modelRef.value.ios_url_raw[0] && !modelRef.value.ios_url_raw[1]) return '';
        return modelRef.value.ios_url_raw[0] + '://' + modelRef.value.ios_url_raw[1];
      }),
      ios_url_raw: ['', ''],
    });
    const editRowRef = ref<Link | null>(null);

    const rules = {
      url: [
        {
          required: true,
          validator(rule: any, value: any) {
            if (!value) {
              return new Error('URL is required');
            } else if (value.length > 2083) {
              return new Error('URL has to be 2083 characters or below.');
            } else if (String(value).startsWith('://')) {
              return new Error('Please enter a protocol.');
            }
            return true;
          },
          trigger: ['input', 'blur'],
        },
      ],
      slug: [
        {
          required: true,
          validator(rule: any, value: any) {
            if (!value) {
              return new Error('Slug is required');
            }
            if (value.length > 50) {
              return new Error('Slug has to be 50 characters or below.');
            }
            return true;
          },
          trigger: ['input', 'blur'],
        },
      ],
      android_url: [
        {
          validator(rule: any, value: any) {
            if (!value) {
              return true;
            }
            if (value.length > 2083) {
              return new Error('Android URL has to be 2083 characters or below.');
            } else if (String(value).startsWith('://')) {
              return new Error('Please enter a protocol.');
            }
            return true;
          },
          trigger: ['input', 'blur'],
        },
      ],
      ios_url: [
        {
          validator(rule: any, value: any) {
            if (!value) {
              return true;
            }
            if (value.length > 2083) {
              return new Error('iOS URL has to be 2083 characters or below.');
            } else if (String(value).startsWith('://')) {
              return new Error('Please enter a protocol.');
            }
            return true;
          },
          trigger: ['input', 'blur'],
        },
      ],
    };

    // Remove confusion with caps I caps O and l
    const nanoid = customAlphabet('1234567890abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ', 6);

    async function handleGenerateSlug() {
      modelRef.value.slug = nanoid();
      try {
        await slugRef.value.validate();
      } catch (error) {
        return;
      }
    }

    async function handleSaveEdits() {
      try {
        await formRef.value.validate();
      } catch (error) {
        return;
      }
      try {
        showLoadingSpinner.value = true;
        if (editRowRef.value) {
          const { error } = await editLink(editRowRef.value.id, {
            url: modelRef.value.url,
            slug: modelRef.value.slug,
            meta: {
              android_url: modelRef.value.android_url,
              ios_url: modelRef.value.ios_url,
            },
          });
          if (error) throw error;

          for (let link of links.value) {
            if (link.id === editRowRef.value!.id) {
              link.url = modelRef.value.url;
              link.slug = modelRef.value.slug;
              link.meta = {
                android_url: modelRef.value.android_url,
                ios_url: modelRef.value.ios_url,
              };
            }
          }
          showEditModal.value = false;
          message.success('Link has been updated successfully', { duration: messageDuration });
        }
      } catch (error) {
        console.log(error);
        message.error('Could not update link', { duration: messageDuration });
      } finally {
        showLoadingSpinner.value = false;
      }
    }

    async function handleDeleteRow(row: Link) {
      const warningDialog = dialog.warning({
        title: 'Delete Link',
        content: `Are you sure you want to delete this link "${row.url}"?`,
        positiveText: 'Delete',
        negativeText: 'Cancel',
        onPositiveClick: async () => {
          try {
            loadingRef.value = true;
            await deleteLink(row.id);
            links.value = links.value.filter((link) => link.id !== row.id);
            message.success('Link has been deleted successfully', { duration: messageDuration });
          } catch (error) {
            console.log(error);
            message.error('Could not delete link', { duration: messageDuration });
          } finally {
            loadingRef.value = false;
          }
        },
      });
    }

    async function handleEditRow(row: Link) {
      editRowRef.value = row;
      showEditModal.value = true;
      modelRef.value.url_raw = row.url.split('://');
      modelRef.value.slug = row.slug;
      modelRef.value.android_url_raw = row.meta?.android_url ? row.meta.android_url.split('://') : ['', ''];
      modelRef.value.ios_url_raw = row.meta?.ios_url ? row.meta.ios_url.split('://') : ['', ''];
    }

    const rowKey = (row: Link) => row.id as string;

    const columns = [
      {
        title: 'URL',
        key: 'url',
        render(row: Link) {
          return row.url;
        },
      },
      {
        title: 'Short URL',
        key: 'short-url',
        render(row: Link) {
          return `${window.location.hostname}/${row.slug}`;
        },
      },
      {
        title: 'TTL',
        key: 'ttl',
        render(row: Link) {
          const expiryDate = new Date(row.expiryDate); // Assuming the link has an expiryDate property
          const now = new Date();
          const ttl = Math.max(0, Math.floor((expiryDate.getTime() - now.getTime()) / 1000)); // Time left in seconds

          const days = Math.floor(ttl / (24 * 60 * 60));
          const hours = Math.floor((ttl % (24 * 60 * 60)) / (60 * 60));
          const minutes = Math.floor((ttl % (60 * 60)) / 60);
          const seconds = ttl % 60;

          return `${days}d ${hours}h ${minutes}m ${seconds}s`;
        },
      },
      {
        title: 'Actions',
        key: 'actions',
        render(row: Link) {
          return h('div', [
            h(
              NButton,
              {
                size: 'small',
                type: 'primary',
                style: { marginRight: '10px' },
                onClick: () => handleEditRow(row),
              },
              { default: () => 'Edit' }
            ),
            h(
              NButton,
              {
                size: 'small',
                type: 'error',
                onClick: () => handleDeleteRow(row),
              },
              { default: () => 'Delete' }
            ),
          ]);
        },
      },
    ];

    onMounted(async () => {
      loadingRef.value = true;
      try {
        await linksStore.fetchLinks();
        links.value = linksStore.links;
      } catch (error) {
        console.log(error);
        message.error('Could not fetch links', { duration: messageDuration });
      } finally {
        loadingRef.value = false;
      }
    });

    function handleUrlUpdate(val: any) {
			if (String(val[0]).includes('://')) {
				const splits = String(val[0]).split('://');
				if (splits.length > 1) {
					modelRef.value.url_raw[0] = splits[0];
					modelRef.value.url_raw[1] = splits.slice(1).join('://');
				}
			} else if (String(val[1]).includes('://')) {
				const splits = String(val[1]).split('://');
				if (splits.length > 1) {
					if (!val[0] || val[0] === splits[0]) {
						modelRef.value.url_raw[0] = splits[0];
						modelRef.value.url_raw[1] = splits.slice(1).join('://');
					}
				}
			}
		}

		function handleAndroidUrlUpdate(val: any) {
			if (String(val[0]).includes('://')) {
				const splits = String(val[0]).split('://');
				if (splits.length > 1) {
					modelRef.value.android_url_raw[0] = splits[0];
					modelRef.value.android_url_raw[1] = splits.slice(1).join('://');
				}
			} else if (String(val[1]).includes('://')) {
				const splits = String(val[1]).split('://');
				if (splits.length > 1) {
					if (!val[0] || val[0] === splits[0]) {
						modelRef.value.android_url_raw[0] = splits[0];
						modelRef.value.android_url_raw[1] = splits.slice(1).join('://');
					}
				}
			}
		}

		function handleIosUrlUpdate(val: any) {
			if (String(val[0]).includes('://')) {
				const splits = String(val[0]).split('://');
				if (splits.length > 1) {
					modelRef.value.ios_url_raw[0] = splits[0];
					modelRef.value.ios_url_raw[1] = splits.slice(1).join('://');
				}
			} else if (String(val[1]).includes('://')) {
				const splits = String(val[1]).split('://');
				if (splits.length > 1) {
					if (!val[0] || val[0] === splits[0]) {
						modelRef.value.ios_url_raw[0] = splits[0];
						modelRef.value.ios_url_raw[1] = splits.slice(1).join('://');
					}
				}
			}
		}

    return {
      loadingRef,
      links,
      rowKey,
      columns,
      showEditModal,
      formRef,
      showLoadingSpinner,
      model: modelRef.value,
      rules,
      handleSaveEdits,
      handleGenerateSlug,
      handleEditRow,
      handleDeleteRow,
      pagination: reactive({
        page: 1,
        pageSize: 10,
        showSizePicker: true,
        pageSizes: [10, 20, 30, 40],
        itemCount: links.value.length,
      }),
      handleUrlUpdate,
      handleAndroidUrlUpdate,
      handleIosUrlUpdate,
      fetchLinks: linksStore.fetchLinks,
    };
  },
});
</script>

<style scoped>
.centered-view {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100%;
  flex-direction: column;
}
.url-input {
  flex: 1;
}
.centered-form {
  display: flex;
  flex-direction: column;
  width: 100%;
}
</style>
